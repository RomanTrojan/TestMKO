unit unMain;

interface

uses
  Windows, System.SysUtils, System.Variants, System.Classes,
  IOUtils, Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  frFeature,
  MKO.Types, MKO.Features, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TmtMain = class(TForm)
    tvFeatures: TTreeView;
    pgcProperties: TPageControl;
    tsLibrary: TTabSheet;
    tsFeature: TTabSheet;
    frFeatureProperty: TfrFeatureProperty;
    spl1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;
    procedure FormDestroy(Sender: TObject);
    procedure tvFeaturesChange(Sender: TObject; Node: TTreeNode);

  private
    FActiveFeature: TFeature;
    FModules: TModuleList;
    function LoadModules: integer;
    procedure ShowControls;
    procedure UnloadModules;
    procedure FeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);

  public

  end;

var
  mtMain: TmtMain;

implementation

{$R *.dfm}

procedure doLog(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;
begin
  TThread.Queue(nil, procedure
  begin
    mtMain.Log(LibraryGUID, Feature, LogMessage, Kind)
  end);
end;

procedure TmtMain.FormCreate(Sender: TObject);
begin
  LoadModules;
  ShowControls;
end;

procedure TmtMain.FormDestroy(Sender: TObject);
begin
  UnloadModules;
end;

procedure TmtMain.FeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
begin
  if FActiveFeature = Feature then
    TThread.Queue(nil, procedure
    begin
      frFeatureProperty.UpdateView;
    end);
end;

function TmtMain.LoadModules: integer;
var
  Path: string;
  Files: TStringDynArray;
  i: integer;
  Module: TModule;
  Features: string;
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
      Module.LibraryName := ChangeFileExt(ExtractFileName(Files[i]), '');
      Module.LibHandle := LoadLibrary(PChar(Files[i]));
      if (Module.LibHandle > 0) and Module.Init then
      begin
        Module.OnFeatureNotify := FeatureNotify;
        Module.RegisterLogCallbackProc(doLog);
        FModules.Add(Module);
      end;
    end;
  end;
  result := FModules.Count;
end;

procedure TmtMain.Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind);
begin
//  m1.Lines.Add(Format('[%s] %s: %s', [LibraryGUID, Feature, LogMessage]));
end;

procedure TmtMain.ShowControls;
var
  i, j: integer;
  ModuleNode, FeatureNode: TTreeNode;
  p: Pointer;
begin
  tvFeatures.Items.BeginUpdate;
  try
    tvFeatures.Items.Clear;
    for i := 0 to FModules.Count - 1 do
    begin
      ModuleNode := tvFeatures.Items.AddChildObject(nil, FModules[i].Info.Caption, Pointer(FModules[i]));
      ModuleNode.ImageIndex := 2;
      ModuleNode.SelectedIndex := 2;
      for j := 0 to FModules[i].Features.Count - 1 do
      begin
        FeatureNode := tvFeatures.Items.AddChildObject(ModuleNode, FModules[i].Features[j].Caption, Pointer(FModules[i].Features[j]));
        FeatureNode.ImageIndex := 1;
        FeatureNode.SelectedIndex := 1;
      end;
    end;
  finally
    tvFeatures.Items.EndUpdate;
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

procedure TmtMain.UnloadModules;
var
  i: integer;
begin
  for I := 0 to FModules.Count - 1 do
    FModules[i].FreeResources;
end;

end.
