unit frFeature;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.Grids, Vcl.ValEdit;

type
  TfrFeatureProperty = class(TFrame)
    lTaskCaption: TLabel;
    pbProgress: TProgressBar;
    lCurrentOperation: TLabel;
    pStartedAt: TPanel;
    lStartedAtHint: TLabel;
    lStartedAt: TLabel;
    pElapsedTime: TPanel;
    lElapsedTimeHint: TLabel;
    lElapsedTime: TLabel;
    bvlSeparator: TBevel;
    mLog: TMemo;
    pHeader: TPanel;
    shpStatus: TShape;
    ilImages: TImageList;
    btTastAction: TButton;
    le1: TValueListEditor;
    pInfo: TPanel;
    pTop: TPanel;
    pRunParams: TPanel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
