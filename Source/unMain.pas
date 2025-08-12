unit unMain;

interface

uses
  Windows, System.SysUtils, System.Variants, System.Classes,
  IOUtils, Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,

  frFeature,
  MKO.Types,
  MKO.Features;

type
  TmtMain = class(TForm)
    tvFeatures: TTreeView;
    pgcProperties: TPageControl;
    tsLibrary: TTabSheet;
    tsFeature: TTabSheet;
    spl1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure tvFeaturesChange(Sender: TObject; Node: TTreeNode);
    procedure FormDestroy(Sender: TObject);

  private
    FActiveFeature: TFeature;
    FModules: TModuleList;
    frFeatureProperty: TfrFeatureProperty;
    procedure Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;
    procedure Progress(const LibraryGUID, Feature, CurrentOperation: string; Progress: integer); stdcall;
    function LoadModules: integer;
    procedure ShowControls;
    procedure FeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
    function FindFeatureNode(Feature: TFeature): TTreeNode;

  public

  end;

var
  mtMain: TmtMain;

implementation

{$R *.dfm}

procedure doLog(const LibraryGUID, Feature, LogMessage: ShortString; Kind: TLogKind); stdcall;
begin
  TThread.Queue(nil, procedure
  begin
    mtMain.Log(String(LibraryGUID), String(Feature), String(LogMessage), Kind)
  end);
end;

procedure doProgress(const LibraryGUID, Feature, CurrentOperation: ShortString; Progress: integer); stdcall;
begin
  TThread.Queue(nil, procedure
  begin
    mtMain.Progress(String(LibraryGUID), String(Feature), String(CurrentOperation), Progress);
  end);
end;

procedure TmtMain.FormCreate(Sender: TObject);
begin
  frFeatureProperty := TfrFeatureProperty.Create(self);
  frFeatureProperty.Parent := tsFeature;
  frFeatureProperty.Align := alClient;
  tvFeatures.Images := frFeatureProperty.ilImages;

  LoadModules;
  ShowControls;
end;

procedure TmtMain.FormDestroy(Sender: TObject);
begin
  FModules.Free;
end;

function TmtMain.FindFeatureNode(Feature: TFeature): TTreeNode;

  function Found(Node: TTreeNode; out res: TTreeNode): boolean;
  var
    Child: TTreeNode;
  begin
    result := (TObject(Node.Data) is TFeature) and (TFeature(Node.Data) = Feature);
    if result then
      res := Node
    else
    begin
      Child := Node.getFirstChild;
      while Assigned(Child) and not Result do
      begin
        result := Found(Child, res);
        Child := Child.getNextSibling;
      end;
    end;
  end;

var
  i: integer;
begin
  result := nil;
  for i := 0 to tvFeatures.Items.Count - 1 do
    if Found(tvFeatures.Items[i], result) then
      exit;
end;

procedure TmtMain.FeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
begin
  TThread.Queue(nil, procedure
  var
    Node: TTreeNode;
  begin
    if FActiveFeature = Feature then
      frFeatureProperty.UpdateView(false);
    Node := FindFeatureNode(Feature);
    if Assigned(Node) then
    begin
      case Action of
        nStart:  Node.ImageIndex := 0;
        nFinish: Node.ImageIndex := 1;
      end;
      Node.SelectedIndex := Node.ImageIndex;
    end;
  end);
end;

function TmtMain.LoadModules: integer;
var
  Path: string;
  Files: TStringDynArray;
  i: integer;
  Module: TModule;
begin
  if not Assigned(FModules) then
    FModules := TModuleList.Create
  else
    FModules.Clear;

  Path := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'Modules');
  if DirectoryExists(Path) then
  begin
    Files := TDirectory.GetFiles(Path, '*.dll');
    for I := 0 to Length(Files) - 1 do
    begin
      Module := TModule.Create;
      Module.LibraryName := Files[i];
      Module.LibHandle := LoadLibrary(PChar(Files[i]));
      if (Module.LibHandle > 0) then
      begin
        if Module.Init then
        begin
          Module.OnFeatureNotify := FeatureNotify;
          Module.RegisterLogCallbackProc(doLog);
          Module.RegisterProgressCallbackProc(doProgress);
          FModules.Add(Module);
        end
        else
          FreeLibrary(Module.LibHandle);
      end;
    end;
  end;
  result := FModules.Count;
end;

procedure TmtMain.Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind);
var
  AFeature: TFeature;
begin
  AFeature := FModules.FindFeature(LibraryGUID, Feature);
  if Assigned(AFeature) then
  begin
    AFeature.AddLog(LogMessage, Kind);
    if AFeature = FActiveFeature then
      frFeatureProperty.mLog.Lines.Add(LogMessage);
  end;
end;

procedure TmtMain.Progress(const LibraryGUID, Feature, CurrentOperation: string; Progress: integer);
var
  AFeature: TFeature;
begin
  AFeature := FModules.FindFeature(LibraryGUID, Feature);
  if Assigned(AFeature) then
  begin
    AFeature.Status.CurrentOperation := CurrentOperation;
    AFeature.Status.Progress := Progress;
    if AFeature = FActiveFeature then
      frFeatureProperty.UpdateView(false);
  end;
end;

procedure TmtMain.ShowControls;
var
  i, j: integer;
  ModuleNode, FeatureNode: TTreeNode;
begin
  tvFeatures.Items.BeginUpdate;
  try
    tvFeatures.Items.Clear;
    for i := 0 to FModules.Count - 1 do
    begin
      ModuleNode := tvFeatures.Items.AddChildObject(nil, String(FModules[i].Info.Caption), Pointer(FModules[i]));
      ModuleNode.ImageIndex := 2;
      ModuleNode.SelectedIndex := 2;
      for j := 0 to FModules[i].Features.Count - 1 do
      begin
        FeatureNode := tvFeatures.Items.AddChildObject(ModuleNode, FModules[i].Features[j].Caption, Pointer(FModules[i].Features[j]));
        FeatureNode.ImageIndex := 1;
        FeatureNode.SelectedIndex := FeatureNode.ImageIndex;
      end;
    end;
  finally
    tvFeatures.Items.EndUpdate;
    tvFeatures.FullExpand;
  end;
end;

procedure TmtMain.tvFeaturesChange(Sender: TObject; Node: TTreeNode);
begin
  if Node.ImageIndex = 2 then
  begin
    FActiveFeature := nil;
    pgcProperties.ActivePage := tsLibrary;
  end
  else
  begin
    FActiveFeature := TFeature(Node.Data);
    frFeatureProperty.Feature := FActiveFeature;
    pgcProperties.ActivePage := tsFeature;
  end;
end;

end.
