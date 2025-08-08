unit unMain;

interface

uses
  Windows, System.SysUtils, System.Variants, System.Classes,
  IOUtils, Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  frFeature,
  MKO.Types, MKO.Features, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TmtMain = class(TForm)
    bt1: TButton;
    m1: TMemo;
    tvFeatures: TTreeView;
    pgcProperties: TPageControl;
    ts1: TTabSheet;
    ts2: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure bt1Click(Sender: TObject);
    procedure Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;

  private
    FModules: TModuleList;

    function LoadModules: integer;
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

procedure TmtMain.bt1Click(Sender: TObject);
var
  Params: TRunParamsInfo;
begin
  TThread.CreateAnonymousThread(procedure
  begin
    FModules[0].RunFeatureProc(FModules[0].Features[0].Name, Params);
  end).Start;
end;

procedure TmtMain.FormCreate(Sender: TObject);
begin
  LoadModules;
  with TfrFeatureProperty.Create(self) do
  begin
    Parent := ts2;
    Align := alClient;
  end;
end;

function TmtMain.LoadModules: integer;
var
  Path: string;
  Files: TStringDynArray;
  i: integer;
  Module: TModule;
  Features: string;
begin
  FModules := TModuleList.Create;
  Path := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'Modules');
  Files := TDirectory.GetFiles(Path, '*.dll');
  for I := 0 to Length(Files) - 1 do
  begin
    Module := TModule.Create;
    Module.LibraryName := ChangeFileExt(ExtractFileName(Files[i]), '');
    Module.LibHandle := LoadLibrary(PChar(Files[i]));
    if (Module.LibHandle > 0) and Module.Init then
    begin
      Module.RegisterLogCallbackProc(doLog);
      FModules.Add(Module);
    end;
  end;
  result := FModules.Count;
end;

procedure TmtMain.Log(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind);
begin
  m1.Lines.Add(Format('[%s] %s: %s', [LibraryGUID, Feature, LogMessage]));
end;

end.
