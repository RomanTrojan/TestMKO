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
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object spl1: TSplitter
    Left = 177
    Top = 0
    Height = 370
    ExplicitLeft = 175
    ExplicitTop = -24
  end
  object tvFeatures: TTreeView
    Left = 0
    Top = 0
    Width = 177
    Height = 370
    Align = alLeft
    Images = frFeatureProperty.ilImages
    Indent = 19
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    OnChange = tvFeaturesChange
  end
  object pgcProperties: TPageControl
    Left = 180
    Top = 0
    Width = 673
    Height = 370
    ActivePage = tsFeature
    Align = alClient
    TabOrder = 1
    object tsLibrary: TTabSheet
      Caption = 'tsLibrary'
      TabVisible = False
    end
    object tsFeature: TTabSheet
      Caption = 'tsFeature'
      ImageIndex = 1
      TabVisible = False
      inline frFeatureProperty: TfrFeatureProperty
        Left = 0
        Top = 0
        Width = 665
        Height = 360
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 665
        ExplicitHeight = 360
        inherited mLog: TMemo
          Width = 665
          Height = 201
          ExplicitWidth = 665
          ExplicitHeight = 201
        end
        inherited pTop: TPanel
          Width = 665
          ExplicitWidth = 665
          inherited pInfo: TPanel
            ExplicitLeft = -1
            ExplicitTop = -6
            inherited lCurrentOperation: TLabel
              Height = 13
              ExplicitLeft = 2
              ExplicitWidth = 283
              ExplicitHeight = 13
            end
            inherited bvlSeparator: TBevel
              Top = 38
              ExplicitLeft = 2
              ExplicitTop = 32
            end
            inherited pStartedAt: TPanel
              Top = 44
              ExplicitLeft = 2
              ExplicitTop = 25
              inherited lStartedAt: TLabel
                Width = 144
                Align = alLeft
                ExplicitWidth = 144
              end
            end
            inherited pElapsedTime: TPanel
              Top = 71
              ExplicitTop = 44
              inherited lElapsedTime: TLabel
                ExplicitWidth = 160
                ExplicitHeight = 21
              end
            end
          end
          inherited pRunParams: TPanel
            Width = 376
            ExplicitWidth = 376
            inherited le1: TValueListEditor
              Width = 374
              ExplicitWidth = 374
              ColWidths = (
                99
                269)
            end
            inherited btTastAction: TButton
              Width = 368
              ExplicitWidth = 368
            end
          end
        end
        inherited pHeader: TPanel
          Width = 665
          ExplicitWidth = 665
          inherited lTaskCaption: TLabel
            Width = 629
            ExplicitWidth = 629
          end
        end
      end
    end
  end
end
