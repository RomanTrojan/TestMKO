object mtMain: TmtMain
  Left = 0
  Top = 0
  Caption = #1052#1050#1054
  ClientHeight = 370
  ClientWidth = 853
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object bt1: TButton
    Left = 448
    Top = 24
    Width = 75
    Height = 25
    Caption = 'bt1'
    TabOrder = 0
    OnClick = bt1Click
  end
  object m1: TMemo
    Left = 360
    Top = 64
    Width = 425
    Height = 217
    Lines.Strings = (
      'm1')
    TabOrder = 1
  end
  object tvFeatures: TTreeView
    Left = 0
    Top = 0
    Width = 177
    Height = 370
    Align = alLeft
    Indent = 19
    TabOrder = 2
  end
  object pgcProperties: TPageControl
    Left = 177
    Top = 0
    Width = 152
    Height = 370
    ActivePage = ts2
    Align = alLeft
    TabOrder = 3
    object ts1: TTabSheet
      Caption = 'ts1'
      TabVisible = False
      ExplicitWidth = 668
    end
    object ts2: TTabSheet
      Caption = 'ts2'
      ImageIndex = 1
      TabVisible = False
      ExplicitWidth = 668
    end
  end
end
