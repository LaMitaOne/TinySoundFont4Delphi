unit Unit1;

{==============================================================================*
 *  TinySoundFont - High Precision Threaded Audio Demo (Double Buffered)
 *------------------------------------------------------------------------------
 *  This demo shows how to use the TinySoundFont wrapper in Delphi.
 *  Features:
 *  - Fixed dynamic UI Piano (TPanels)
 *  - Audio Thread starts on Soundfont load (Live Play enabled immediately)
 *  - Sequencer triggers on btnPlayTing, loops infinitely, stops on btnStop
 *==============================================================================}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, MMSystem, TinySoundFont, Vcl.Controls, Vcl.ExtCtrls,
  System.SyncObjs, System.Diagnostics, Vcl.Graphics;

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

    FBuffer: PSingle;
    FWaveHdr: array[0..1] of TWaveHdr;
    FChunkBytes: Cardinal;
    FAudioThread: TThread;
    FLock: TCriticalSection;
    FIsPlaying: Boolean;

    FMelody: array[0..15, 0..1] of Double;
    FNoteIndex: Integer;
    FNextNoteTime: Double;
    FPlaySequence: Boolean;

    procedure LoadTSFDLL;
    procedure InitMMSystem;
    procedure CloseMMSystem;
    procedure StartAudioThread;
    procedure StopAudioThread;

    procedure CreatePianoKeys;
    procedure PlayLiveNote(Note: Integer);
    procedure KeyPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure KeyPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  WAVE_FORMAT_IEEE_FLOAT = 3;
  PIANO_START_NOTE = 48;
  PIANO_OCTAVES = 2;

  // Fixed layout sizes
  WHITE_KEY_W = 40;
  BLACK_KEY_W = 28;   // INCREASED slightly for better clickability
  KEYBOARD_TOP = 140;
  KEYBOARD_BOTTOM_MARGIN = 10;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FTSF := nil;
  FDLLLoaded := False;
  FWaveOut := 0;
  FBuffer := nil;
  FLock := TCriticalSection.Create;
  FIsPlaying := False;
  FPlaySequence := False;

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

  // Build the visual Piano dynamically ONCE
  CreatePianoKeys;
end;

procedure TForm1.CreatePianoKeys;
const
  // 0 = No key, 1 = White Key, 2 = Black Key
  KeyPattern: array[0..11] of Integer = (1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 1);
var
  I, Octave: Integer;
  CurrentNote: Integer;
  X: Integer;
  Pnl: TPanel;
  BlackKeyOffset: Integer;
  WhiteKeyH, BlackKeyH: Integer;
begin
  BlackKeyOffset := (WHITE_KEY_W - BLACK_KEY_W) div 2;
  X := 10;
  CurrentNote := PIANO_START_NOTE;

  WhiteKeyH := ClientHeight - KEYBOARD_TOP - KEYBOARD_BOTTOM_MARGIN;
  BlackKeyH := (WhiteKeyH * 62) div 100;

  for Octave := 0 to PIANO_OCTAVES - 1 do
  begin
    for I := 0 to 11 do
    begin
      if KeyPattern[I] = 1 then
      begin
        // White Key
        Pnl := TPanel.Create(Self);
        Pnl.Parent := Self;
        Pnl.SetBounds(X, KEYBOARD_TOP, WHITE_KEY_W, WhiteKeyH);

        if (CurrentNote mod 12) = 0 then
          Pnl.Caption := 'C' + IntToStr((CurrentNote div 12) - 1)
        else
          Pnl.Caption := '';

        Pnl.Tag := CurrentNote;
        Pnl.Hint := 'W';
        Pnl.OnMouseDown := KeyPanelMouseDown;
        Pnl.OnMouseUp := KeyPanelMouseUp;
        Pnl.Font.Style := [fsBold];
        Pnl.Color := clWhite;
        Pnl.ParentBackground := False;
        Pnl.BevelOuter := bvNone;
        Pnl.BevelKind := bkTile;
        Pnl.Anchors := [akLeft, akTop];

        X := X + WHITE_KEY_W;
      end
      else if KeyPattern[I] = 2 then
      begin
        // Black Key (Direct on Form, overlaid on top of White Key visually)
        Pnl := TPanel.Create(Self);
        Pnl.Parent := Self;
        Pnl.BringToFront;

        Pnl.SetBounds(X - BlackKeyOffset, KEYBOARD_TOP, BLACK_KEY_W, BlackKeyH);
        Pnl.Caption := '';
        Pnl.Tag := CurrentNote + 1;
        Pnl.Hint := 'B';
        Pnl.OnMouseDown := KeyPanelMouseDown;
        Pnl.OnMouseUp := KeyPanelMouseUp;
        Pnl.Color := clBlack;
        Pnl.ParentBackground := False;
        Pnl.BevelOuter := bvNone;
        Pnl.BevelKind := bkTile;
        Pnl.Anchors := [akLeft, akTop];
        Pnl.BringToFront;
      end;

      CurrentNote := CurrentNote + 1;
    end;
  end;
end;

procedure TForm1.KeyPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and Assigned(FTSF) then
  begin
    PlayLiveNote(TPanel(Sender).Tag);
    TPanel(Sender).Color := clBtnFace;
  end;
end;

procedure TForm1.KeyPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if TPanel(Sender).Hint = 'B' then
    TPanel(Sender).Color := clBlack
  else
    TPanel(Sender).Color := clWhite;
end;

procedure TForm1.PlayLiveNote(Note: Integer);
begin
  if Assigned(FTSF) then
    tsf_channel_note_on(FTSF, 0, Note, 1.0);
end;

procedure TForm1.LoadTSFDLL;
var
  DllPath: string;
begin
  DllPath := ExtractFilePath(ParamStr(0)) + 'tinysoundfont.dll';
  FTSFDLL := SafeLoadLibrary(DllPath);
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

  FChunkBytes := 176400;
  GetMem(FBuffer, FChunkBytes * 2);
  FillChar(FBuffer^, FChunkBytes * 2, 0);

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

      FPlaySequence := False;
      FIsPlaying := True;
      StartAudioThread;

      lblStatus.Caption := 'Soundfont loaded! Play the piano or click Play Ting.';
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
  FPlaySequence := True;
  lblStatus.Caption := 'Playing sequence...';
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  FPlaySequence := False;
  lblStatus.Caption := 'Sequence stopped. Live piano still active.';
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

      FramesToRender := 22050;
      SpinTicks := (2000000 * Freq) div 1000000000; // 2ms
      BufIndex := 0;

      TargetTicks := Timer.GetTimestamp;

      while FIsPlaying do
      begin
        // 1. SEQUENCER LOGIC
        if FPlaySequence then
        begin
          CurrentTime := Timer.Elapsed.TotalSeconds;
          while CurrentTime >= FNextNoteTime do
          begin
            Inc(FNoteIndex);

            if FNoteIndex >= Length(FMelody) then
              FNoteIndex := 0;

            if FMelody[FNoteIndex, 0] > 0 then
              tsf_channel_note_on(FTSF, 0, Round(FMelody[FNoteIndex, 0]), 1.0);

            FNextNoteTime := FNextNoteTime + FMelody[FNoteIndex, 1];
            CurrentTime := Timer.Elapsed.TotalSeconds;
          end;
        end;

        // 2. RENDER AUDIO CHUNK
        tsf_render_float(FTSF, System.PSingle(FWaveHdr[BufIndex].lpData), FramesToRender, 0);

        // 3. QUEUE BUFFER TO SOUNDCARD
        waveOutWrite(FWaveOut, @FWaveHdr[BufIndex], SizeOf(TWaveHdr));

        // 4. SWITCH BUFFER (Ping-Pong)
        BufIndex := BufIndex xor 1;

        // 5. PRECISE PACING
        TargetTicks := TargetTicks + (Freq div 2);
        NowTicks := Timer.GetTimestamp;
        if TargetTicks <= NowTicks then
          TargetTicks := NowTicks + (Freq div 2);

        // Hybrid Sleep/Spin
        while (TargetTicks - Timer.GetTimestamp) > SpinTicks do
          Sleep(1);
        while Timer.GetTimestamp < TargetTicks do ;
      end;

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
