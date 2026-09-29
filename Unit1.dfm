object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 442
  ClientWidth = 628
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
    Left = 72
    Top = 192
    Width = 45
    Height = 15
    Caption = 'lblStatus'
  end
  object btnLoadSoundfont: TButton
    Left = 40
    Top = 72
    Width = 75
    Height = 25
    Caption = 'LoadSoundfont'
    TabOrder = 0
    OnClick = btnLoadSoundfontClick
  end
  object btnInitAudio: TButton
    Left = 40
    Top = 32
    Width = 75
    Height = 25
    Caption = 'init'
    TabOrder = 1
    OnClick = btnInitAudioClick
  end
  object btnPlayTing: TButton
    Left = 40
    Top = 120
    Width = 75
    Height = 25
    Caption = 'play'
    TabOrder = 2
    OnClick = btnPlayTingClick
  end
  object OpenDialog1: TOpenDialog
    Left = 112
    Top = 136
  end
end
