unit Unit1;

{==============================================================================*
 *  TinySoundFont - High Precision Threaded Audio Demo (Double Buffered)
 *------------------------------------------------------------------------------
 *  This demo shows how to use the TinySoundFont wrapper in Delphi.
 *  Uses a background thread with QPC (TStopwatch) and Double Buffering
 *  to provide seamless, crackle-free audio without blocking the UI.
 *==============================================================================}
interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, MMSystem, TinySoundFont, Vcl.Controls, Vcl.ExtCtrls,
  System.SyncObjs, System.Diagnostics;

type
  TForm1 = class(TForm)
    btnInitAudio: TButton;
    btnLoadSoundfont: TButton;
    btnPlayTing: TButton;
    OpenDialog1: TOpenDialog;
    lblStatus: TLabel;
    btnStop: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitAudioClick(Sender: TObject);
    procedure btnLoadSoundfontClick(Sender: TObject);
    procedure btnPlayTingClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FTSFDLL: HMODULE;
    FTSF: Ptsf;
    FDLLLoaded: Boolean;
    FWaveOut: HWAVEOUT;

    // Double Buffering Setup (2x 500ms = 1 Second total)
    FBuffer: PSingle;
    FWaveHdr: array[0..1] of TWaveHdr;
    FChunkBytes: Cardinal;

    FAudioThread: TThread;
    FLock: TCriticalSection;
    FIsPlaying: Boolean;

    // Melody: [Note, Duration in seconds]
    FMelody: array[0..15, 0..1] of Double;
    FNoteIndex: Integer;
    FNextNoteTime: Double;

    procedure LoadTSFDLL;
    procedure InitMMSystem;
    procedure CloseMMSystem;
    procedure StartAudioThread;
    procedure StopAudioThread;
  public
    { Public Declarations }
  end;

var
  Form1: TForm1;

implementation
{$R *.dfm}

const
  WAVE_FORMAT_IEEE_FLOAT = 3;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FTSF := nil;
  FDLLLoaded := False;
  FWaveOut := 0;
  FBuffer := nil;
  FLock := TCriticalSection.Create;
  FIsPlaying := False;

  lblStatus.Caption := 'Ready. Please initialize Audio...';

  // Melody Definitions [MIDI Note, Duration in seconds]
  FMelody[0, 0]  := 60; FMelody[0, 1]  := 0.25;
  FMelody[1, 0]  := 64; FMelody[1, 1]  := 0.25;
  FMelody[2, 0]  := 67; FMelody[2, 1]  := 0.25;
  FMelody[3, 0]  := 72; FMelody[3, 1]  := 0.25;
  FMelody[4, 0]  := 67; FMelody[4, 1]  := 0.25;
  FMelody[5, 0]  := 64; FMelody[5, 1]  := 0.25;
  FMelody[6, 0]  := 60; FMelody[6, 1]  := 0.25;
  FMelody[7, 0]  := 0;  FMelody[7, 1]  := 0.50;
  FMelody[8, 0]  := 60; FMelody[8, 1]  := 0.15;
  FMelody[9, 0]  := 62; FMelody[9, 1]  := 0.15;
  FMelody[10, 0] := 64; FMelody[10, 1] := 0.15;
  FMelody[11, 0] := 65; FMelody[11, 1] := 0.15;
  FMelody[12, 0] := 67; FMelody[12, 1] := 0.50;
  FMelody[13, 0] := 0;  FMelody[13, 1] := 0.50;
  FMelody[14, 0] := 72; FMelody[14, 1] := 0.50;
  FMelody[15, 0] := 0;  FMelody[15, 1] := 1.00;
end;

procedure TForm1.LoadTSFDLL;
begin
  FTSFDLL := SafeLoadLibrary(ExtractFilePath(ParamStr(0)) + 'tinysoundfont.dll');
  if FTSFDLL = 0 then
  begin
    lblStatus.Caption := 'Error: tinysoundfont.dll not found!';
    Exit;
  end;
  @tsf_load_filename := GetProcAddress(FTSFDLL, 'dll_tsf_load_filename');
  @tsf_close := GetProcAddress(FTSFDLL, 'dll_tsf_close');
  @tsf_set_output := GetProcAddress(FTSFDLL, 'dll_tsf_set_output');
  @tsf_note_on := GetProcAddress(FTSFDLL, 'dll_tsf_note_on');
  @tsf_render_float := GetProcAddress(FTSFDLL, 'dll_tsf_render_float');
  @tsf_channel_set_presetnumber := GetProcAddress(FTSFDLL, 'dll_tsf_channel_set_presetnumber');
  @tsf_channel_note_on := GetProcAddress(FTSFDLL, 'dll_tsf_channel_note_on');

  if Assigned(tsf_load_filename) and Assigned(tsf_set_output) and Assigned(tsf_render_float) then
    FDLLLoaded := True
  else
    lblStatus.Caption := 'Error: DLL functions not found!';
end;

procedure TForm1.btnInitAudioClick(Sender: TObject);
begin
  if not FDLLLoaded then
    LoadTSFDLL;
  if not FDLLLoaded then
    Exit;
  InitMMSystem;
  if FWaveOut <> 0 then
    lblStatus.Caption := 'Audio Engine running! Please load a Soundfont.'
  else
    lblStatus.Caption := 'Error starting Audio Engine!';
end;

procedure TForm1.InitMMSystem;
var
  Format: TWaveFormatEx;
begin
  FillChar(Format, SizeOf(Format), 0);
  Format.wFormatTag := WAVE_FORMAT_IEEE_FLOAT;
  Format.nChannels := 2;
  Format.nSamplesPerSec := 44100;
  Format.wBitsPerSample := 32;
  Format.nBlockAlign := (Format.nChannels * Format.wBitsPerSample) div 8;
  Format.nAvgBytesPerSec := Format.nSamplesPerSec * Format.nBlockAlign;

  if waveOutOpen(@FWaveOut, WAVE_MAPPER, @Format, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then
  begin
    FWaveOut := 0;
    Exit;
  end;

  // Allocate 1 Second total, split into 2 halves (500ms each)
  // 500ms = 22050 frames = 176400 bytes
  FChunkBytes := 176400;
  GetMem(FBuffer, FChunkBytes * 2);
  FillChar(FBuffer^, FChunkBytes * 2, 0);

  // Prepare both Wave Headers
  FillChar(FWaveHdr[0], SizeOf(TWaveHdr), 0);
  FWaveHdr[0].lpData := PAnsiChar(FBuffer);
  FWaveHdr[0].dwBufferLength := FChunkBytes;
  waveOutPrepareHeader(FWaveOut, @FWaveHdr[0], SizeOf(TWaveHdr));

  FillChar(FWaveHdr[1], SizeOf(TWaveHdr), 0);
  FWaveHdr[1].lpData := PAnsiChar(FBuffer) + FChunkBytes;
  FWaveHdr[1].dwBufferLength := FChunkBytes;
  waveOutPrepareHeader(FWaveOut, @FWaveHdr[1], SizeOf(TWaveHdr));
end;

procedure TForm1.CloseMMSystem;
begin
  if FWaveOut <> 0 then
  begin
    waveOutReset(FWaveOut);
    waveOutUnprepareHeader(FWaveOut, @FWaveHdr[0], SizeOf(TWaveHdr));
    waveOutUnprepareHeader(FWaveOut, @FWaveHdr[1], SizeOf(TWaveHdr));
    waveOutClose(FWaveOut);
    FWaveOut := 0;
  end;
  if Assigned(FBuffer) then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;
end;

procedure TForm1.btnLoadSoundfontClick(Sender: TObject);
begin
  if FWaveOut = 0 then
  begin
    ShowMessage('Please do Step 1 (Audio Init) first!');
    Exit;
  end;
  OpenDialog1.Filter := 'SoundFont 2 (*.sf2)|*.sf2';
  if OpenDialog1.Execute then
  begin
    if Assigned(FTSF) then
      tsf_close(FTSF);
    FTSF := tsf_load_filename(PAnsiChar(AnsiString(OpenDialog1.FileName)));
    if Assigned(FTSF) then
    begin
      tsf_set_output(FTSF, TSF_STEREO_INTERLEAVED, 44100, 0.0);
      tsf_channel_set_presetnumber(FTSF, 0, 0, 0);
      lblStatus.Caption := 'Soundfont loaded! Ready to play.';
    end
    else
      lblStatus.Caption := 'Error loading Soundfont!';
  end;
end;

procedure TForm1.btnPlayTingClick(Sender: TObject);
begin
  if not Assigned(FTSF) then
  begin
    ShowMessage('Please load a Soundfont first!');
    Exit;
  end;

  FNoteIndex := -1;
  FNextNoteTime := 0;
  FIsPlaying := True;

  StartAudioThread;
  lblStatus.Caption := 'Playing sequence...';
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  StopAudioThread;
  lblStatus.Caption := 'Stopped.';
end;

procedure TForm1.StartAudioThread;
begin
  if Assigned(FAudioThread) then Exit;

  timeBeginPeriod(1);

  FAudioThread := TThread.CreateAnonymousThread(
    procedure
    var
      Timer: TStopwatch;
      Freq: Int64;
      TargetTicks, NowTicks, SpinTicks: Int64;
      FramesToRender: Cardinal;
      CurrentTime: Double;
      BufIndex: Integer;
    begin
      Timer := TStopwatch.Create;
      Timer.Reset;
      Timer.Start;
      Freq := Timer.Frequency;

      // 500ms = 22050 frames
      FramesToRender := 22050;
      SpinTicks := (2000000 * Freq) div 1000000000; // 2ms

      BufIndex := 0;
      // Reset timing to start exactly NOW
      TargetTicks := Timer.GetTimestamp;

      while FIsPlaying do
      begin
        // 1. SEQUENCER LOGIC
        CurrentTime := Timer.Elapsed.TotalSeconds;
        while CurrentTime >= FNextNoteTime do
        begin
          Inc(FNoteIndex);
          if FNoteIndex >= Length(FMelody) then
            FNoteIndex := 0;

          if FMelody[FNoteIndex, 0] > 0 then
            tsf_channel_note_on(FTSF, 0, Round(FMelody[FNoteIndex, 0]), 1.0);

          FNextNoteTime := FNextNoteTime + FMelody[FNoteIndex, 1];
          CurrentTime := Timer.Elapsed.TotalSeconds; // Update for while-loop check
        end;

        // 2. RENDER AUDIO CHUNK (22050 frames)
        // We render directly into the correct half of the memory
        tsf_render_float(FTSF, System.PSingle(FWaveHdr[BufIndex].lpData), FramesToRender, 0);

        // 3. QUEUE BUFFER TO SOUNDCARD (NO waveOutReset!)
        waveOutWrite(FWaveOut, @FWaveHdr[BufIndex], SizeOf(TWaveHdr));

        // 4. SWITCH BUFFER (Ping-Pong)
        BufIndex := BufIndex xor 1; // Toggles between 0 and 1

        // 5. PRECISE PACING (Wait 500ms for the chunk to finish)
        TargetTicks := TargetTicks + (Freq div 2); // 0.5 seconds
        NowTicks := Timer.GetTimestamp;
        if TargetTicks <= NowTicks then
          TargetTicks := NowTicks + (Freq div 2);

        // Hybrid Sleep/Spin
        while (TargetTicks - Timer.GetTimestamp) > SpinTicks do
          Sleep(1);
        while Timer.GetTimestamp < TargetTicks do ;
      end;

      // Cleanup soundcard on stop
      waveOutReset(FWaveOut);
    end);

  FAudioThread.FreeOnTerminate := False;
  FAudioThread.Start;
end;

procedure TForm1.StopAudioThread;
begin
  if not Assigned(FAudioThread) then Exit;

  FIsPlaying := False;
  FAudioThread.WaitFor;
  FreeAndNil(FAudioThread);

  timeEndPeriod(1);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  StopAudioThread;
  if Assigned(FTSF) then
    tsf_close(FTSF);
  CloseMMSystem;
  if FTSFDLL <> 0 then
    FreeLibrary(FTSFDLL);
  FreeAndNil(FLock);
end;

end.
