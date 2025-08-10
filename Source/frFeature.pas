unit frFeature;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.Grids, Vcl.ValEdit,

  System.Actions, Vcl.ActnList,
  MKO.Features, MKO.Types;

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
    alFeature: TActionList;
    acRun: TAction;
    procedure acRunUpdate(Sender: TObject);
    procedure acRunExecute(Sender: TObject);
  private
    FFeature: TFeature;
    procedure SetFeature(AFeature: TFeature);

  public
    procedure UpdateView;
    property Feature: TFeature read FFeature write SetFeature;
  end;

implementation

{$R *.dfm}

{ TfrFeatureProperty }

procedure TfrFeatureProperty.UpdateView;
begin
  lTaskCaption.Caption := FFeature.Caption;
  if FFeature.Status.Run then
  begin
    shpStatus.Brush.Color := clLime;
    lStartedAt.Visible := true;
    lStartedAt.Caption := DateTimeToStr(FFeature.Status.StartedAt);
    lElapsedTime.Visible := true;
    lElapsedTime.Caption := TimeToStr(Now - FFeature.Status.StartedAt);
    lCurrentOperation.Caption := FFeature.Status.CurrentOperation;
  end
  else
  begin
    shpStatus.Brush.Color := clRed;
    lStartedAt.Visible := false;
    lElapsedTime.Visible :=  FFeature.Status.Finished <> 0;
    if lElapsedTime.Visible then
      lElapsedTime.Caption := TimeToStr(FFeature.Status.Finished - FFeature.Status.StartedAt);
  end;
  pbProgress.Position := FFeature.Status.Progress;
end;

procedure TfrFeatureProperty.acRunExecute(Sender: TObject);
var
  Params: TRunParamsInfo;
begin
  SetLength(Params, 1);
  Params[0].Name := 'Path';
  Params[0].Value := 'Path';
  FFeature.Run(Params);
end;

procedure TfrFeatureProperty.acRunUpdate(Sender: TObject);
begin
  acRun.Enabled := Assigned(FFeature) and not FFeature.Status.Run;
end;

procedure TfrFeatureProperty.SetFeature(AFeature: TFeature);
begin
  FFeature := AFeature;
  if Assigned(FFeature) then
    UpdateView;
end;

end.
