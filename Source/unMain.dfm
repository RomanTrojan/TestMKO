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
  OldCreateOrder = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 241
    Top = 0
    Height = 370
    ExplicitLeft = 175
    ExplicitTop = -24
  end
  object tvFeatures: TTreeView
    Left = 0
    Top = 0
    Width = 241
    Height = 370
    Align = alLeft
    Indent = 19
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    OnChange = tvFeaturesChange
  end
  object pgcProperties: TPageControl
    Left = 244
    Top = 0
    Width = 609
    Height = 370
    ActivePage = tsFeature
    Align = alClient
    TabOrder = 1
    ExplicitLeft = 180
    ExplicitWidth = 673
    object tsLibrary: TTabSheet
      Caption = 'tsLibrary'
      TabVisible = False
      ExplicitWidth = 665
    end
    object tsFeature: TTabSheet
      Caption = 'tsFeature'
      ImageIndex = 1
      TabVisible = False
      ExplicitWidth = 665
    end
  end
end
