// фрейм, отображающий выбранную задачу
unit frFeature;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.Grids, Vcl.ValEdit,
  System.Actions, Vcl.ActnList,
  MKO.Features,
  MKO.Types;

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
    leRunParams: TValueListEditor;
    pInfo: TPanel;
    pTop: TPanel;
    pRunParams: TPanel;
    alFeature: TActionList;
    acRun: TAction;
    pgcResult: TPageControl;
    tsResult: TTabSheet;
    tsLog: TTabSheet;
    mResult: TMemo;
    p1: TPanel;
    bt1: TButton;
    tm1sec: TTimer;
    procedure acRunUpdate(Sender: TObject);
    procedure acRunExecute(Sender: TObject);
    procedure bt1Click(Sender: TObject);
    procedure tm1secTimer(Sender: TObject);
  private
    FFeature: TFeature;
    procedure SetFeature(AFeature: TFeature);

  public
    procedure UpdateView(Full: boolean);
    property Feature: TFeature read FFeature write SetFeature;
  end;

implementation

{$R *.dfm}

{ TfrFeatureProperty }

procedure TfrFeatureProperty.UpdateView(Full: boolean);
var
  i: integer;
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
  case FFeature.ResultType of
    varString: mResult.Text := FFeature.Status.LastResult;
  else
    mResult.Text := VarToStr(FFeature.Status.LastResult);
  end;

  if Full then
  begin
    mLog.Lines.Assign(FFeature.Status.Log);

    with leRunParams.Strings do
    try
      BeginUpdate;
      Clear;
      if Feature.LastRunParams <> '' then
        Text := Feature.LastRunParams
      else
      begin
        for I := 0 to Feature.Params.Count - 1 do
          AddPair(Feature.Params[i].Caption, VarToStr(Feature.Params[i].ADefault));
      end;
    finally
      EndUpdate
    end;
  end;
end;

procedure TfrFeatureProperty.acRunExecute(Sender: TObject);
var
  Params: TRunParamsInfo;
  i: integer;
  Param: TFeatureParam;
begin
  if FFeature.Status.Run then
  begin
    FFeature.Stop;
  end
  else
  begin
    // заполняем параметры
    with leRunParams.Strings do
    begin
      FFeature.LastRunParams := Text;
      for i := 0 to Count - 1 do
      begin
        if ValueFromIndex[i] = '' then
          continue;
        Param := FFeature.Params[i];
        SetLength(Params, Length(Params) + 1);
        Params[High(Params)].Name := ShortString(Param.Name);
        Params[High(Params)].Value := ShortString(ValueFromIndex[i]);
      end;
    end;
    FFeature.Run(Params);
  end;
end;

procedure TfrFeatureProperty.acRunUpdate(Sender: TObject);
begin
  acRun.Enabled := Assigned(FFeature);
  if acRun.Enabled then
  begin
    if FFeature.Status.Run then
    begin
      acRun.Caption := 'Остановить';
      acRun.ImageIndex := 1;
    end
    else
    begin
      acRun.Caption := 'Запустить';
      acRun.ImageIndex := 0;
    end;
  end;
end;

procedure TfrFeatureProperty.bt1Click(Sender: TObject);
begin
  mLog.Clear;
  if Assigned(FFeature) then
    FFeature.Status.Log.Clear;
end;

procedure TfrFeatureProperty.SetFeature(AFeature: TFeature);
var
  Full: boolean;
begin
  Full := FFeature <> AFeature;
  FFeature := AFeature;
  if Assigned(FFeature) then
    UpdateView(Full);
end;

procedure TfrFeatureProperty.tm1secTimer(Sender: TObject);
begin
  if Assigned(FFeature) and FFeature.Status.Run then
    lElapsedTime.Caption := TimeToStr(Now - FFeature.Status.StartedAt);
end;

end.
