unit Unit1;

{==============================================================================*
 *  TinySoundFont - Demo Application
 *------------------------------------------------------------------------------
 *  This demo shows how to use the TinySoundFont wrapper in Delphi.
 *  It uses the classic Windows MMSystem (waveOut) to play the synthesized
 *  audio directly to the default sound card.
 *==============================================================================}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, MMSystem, TinySoundFont, Vcl.Controls;

type
  TForm1 = class(TForm)
    btnInitAudio: TButton;
    btnLoadSoundfont: TButton;
    btnPlayTing: TButton;
    OpenDialog1: TOpenDialog;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitAudioClick(Sender: TObject);
    procedure btnLoadSoundfontClick(Sender: TObject);
    procedure btnPlayTingClick(Sender: TObject);
  private
    FTSFDLL: HMODULE;
    FTSF: Ptsf;
    FDLLLoaded: Boolean;
    FWaveOut: HWAVEOUT;
    FBuffer: PSingle;
    FBufferSize: Cardinal;
    FWaveHdr: TWaveHdr;
    procedure LoadTSFDLL;
    procedure InitMMSystem;
    procedure CloseMMSystem;
  public
    { Public Declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Manually define the Float standard for Windows (missing in some MMSystem versions)
const
  WAVE_FORMAT_IEEE_FLOAT = 3;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FTSF := nil;
  FDLLLoaded := False;
  FWaveOut := 0;
  FBuffer := nil;
  lblStatus.Caption := 'Ready. Please initialize Audio...';
end;

procedure TForm1.LoadTSFDLL;
begin
  FTSFDLL := SafeLoadLibrary(ExtractFilePath(ParamStr(0)) + 'tinysoundfont.dll');
  if FTSFDLL = 0 then
  begin
    lblStatus.Caption := 'Error: tinysoundfont.dll not found!';
    Exit;
  end;

  @tsf_load_filename            := GetProcAddress(FTSFDLL, 'dll_tsf_load_filename');
  @tsf_close                    := GetProcAddress(FTSFDLL, 'dll_tsf_close');
  @tsf_set_output               := GetProcAddress(FTSFDLL, 'dll_tsf_set_output');
  @tsf_note_on                  := GetProcAddress(FTSFDLL, 'dll_tsf_note_on');
  @tsf_render_float             := GetProcAddress(FTSFDLL, 'dll_tsf_render_float');
  @tsf_channel_set_presetnumber := GetProcAddress(FTSFDLL, 'dll_tsf_channel_set_presetnumber');

  if Assigned(tsf_load_filename) and Assigned(tsf_set_output) and Assigned(tsf_render_float) then
    FDLLLoaded := True
  else
    lblStatus.Caption := 'Error: DLL functions not found!';
end;

// BUTTON 1: Initialize the DLL AND the simple Windows sound card (mmsystem)
procedure TForm1.btnInitAudioClick(Sender: TObject);
begin
  if not FDLLLoaded then
    LoadTSFDLL;
  if not FDLLLoaded then Exit;

  InitMMSystem;

  if FWaveOut <> 0 then
    lblStatus.Caption := 'Audio Engine (mmsystem) running! Please load a Soundfont.'
  else
    lblStatus.Caption := 'Error starting Audio Engine!';
end;

procedure TForm1.InitMMSystem;
var
  Format: TWaveFormatEx;
begin
  // 1. Define Windows Audio Format (32-bit Float, 44100 Hz, Stereo)
  FillChar(Format, SizeOf(Format), 0);
  Format.wFormatTag := WAVE_FORMAT_IEEE_FLOAT;
  Format.nChannels := 2;
  Format.nSamplesPerSec := 44100;
  Format.wBitsPerSample := 32;
  Format.nBlockAlign := (Format.nChannels * Format.wBitsPerSample) div 8;
  Format.nAvgBytesPerSec := Format.nSamplesPerSec * Format.nBlockAlign;

  // 2. Open the default sound card
  if waveOutOpen(@FWaveOut, WAVE_MAPPER, @Format, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then
  begin
    FWaveOut := 0;
    Exit;
  end;

  // 3. Allocate Audio Buffer in memory (1 Second = 44100 Frames * 8 Bytes)
  FBufferSize := 44100 * 8;
  GetMem(FBuffer, FBufferSize);
  FillChar(FBuffer^, FBufferSize, 0);

  // 4. Prepare Wave Header
  FillChar(FWaveHdr, SizeOf(FWaveHdr), 0);
  FWaveHdr.lpData := PAnsiChar(FBuffer);
  FWaveHdr.dwBufferLength := FBufferSize;
  waveOutPrepareHeader(FWaveOut, @FWaveHdr, SizeOf(FWaveHdr));
end;

procedure TForm1.CloseMMSystem;
begin
  if FWaveOut <> 0 then
  begin
    waveOutReset(FWaveOut);
    waveOutUnprepareHeader(FWaveOut, @FWaveHdr, SizeOf(FWaveHdr));
    waveOutClose(FWaveOut);
    FWaveOut := 0;
  end;
  if Assigned(FBuffer) then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;
end;

// BUTTON 2: Load Soundfont
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

// BUTTON 3: Fire the "Ting"
procedure TForm1.btnPlayTingClick(Sender: TObject);
var
  FramesToRender: Cardinal;
begin
  if not Assigned(FTSF) then
  begin
    ShowMessage('Please load a Soundfont first!');
    Exit;
  end;

  // 1. Trigger note in the engine (Preset 0, Middle C, Velocity 1.0)
  tsf_note_on(FTSF, 0, 60, 1.0);

  // 2. Render 1 second of audio into our buffer
  FramesToRender := 44100; // 1 second at 44.1 kHz
  FillChar(FBuffer^, FBufferSize, 0); // Clear buffer

  // Force System.PSingle to prevent Delphi type conflicts
  tsf_render_float(FTSF, System.PSingle(FBuffer), FramesToRender, 0);

  // 3. Send buffer to the Windows sound card -> "Ting!"
  waveOutWrite(FWaveOut, @FWaveHdr, SizeOf(FWaveHdr));

  lblStatus.Caption := 'Sound played!';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(FTSF) then
    tsf_close(FTSF);

  CloseMMSystem;

  if FTSFDLL <> 0 then
    FreeLibrary(FTSFDLL);
end;

end.
