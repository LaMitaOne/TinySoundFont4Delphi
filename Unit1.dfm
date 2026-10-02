object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 319
  ClientWidth = 576
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object lblStatus: TLabel
    Left = 16
    Top = 39
    Width = 45
    Height = 15
    Caption = 'lblStatus'
  end
  object btnLoadSoundfont: TButton
    Left = 89
    Top = 8
    Width = 105
    Height = 25
    Caption = 'LoadSoundfont'
    TabOrder = 0
    OnClick = btnLoadSoundfontClick
  end
  object btnInitAudio: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'init'
    TabOrder = 1
    OnClick = btnInitAudioClick
  end
  object btnPlayTing: TButton
    Left = 200
    Top = 8
    Width = 75
    Height = 25
    Caption = 'play'
    TabOrder = 2
    OnClick = btnPlayTingClick
  end
  object btnStop: TButton
    Left = 281
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 3
    OnClick = btnStopClick
  end
  object OpenDialog1: TOpenDialog
    Left = 112
    Top = 136
  end
end
