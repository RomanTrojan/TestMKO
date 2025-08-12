// модуль прилоения, описывающий модули и их задачи
unit MKO.Features;

interface

uses
  Windows,
  Classes,
  SysUtils,
  Generics.Collections,

  MKO.Types;

const
  LOG_LIMIT = 100; // количество последних хранимых записей лога для каждо задачи

type
  TFeature = class;
  TModule = class;

  TFeatureThread = class(TThread)
  private
    FFeature: TFeature;
    FParams: TRunParamsInfo;
  protected
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor CreateAndRun(Feature: TFeature; Params: TRunParamsInfo);
  end;

  TFeatureParam = class
  private
    FRequred: boolean;
    FName: string;
    FCaption: string;
    FParamType: TVarType;
    FDefault: string;
  public
    constructor Create(Info: TFeatureParamInfo);
    property Requred: boolean read FRequred;
    property Name: string read FName;
    property Caption: string read FCaption;
    property ParamType: TVarType read FParamType;
    property ADefault: string read FDefault;
  end;

  TFeatureParamList = class(TObjectList<TFeatureParam>)
    function Find(const Name: string): TFeatureParam;
  end;

  TFeatureStatus = class
  private
    FLastResult: String;
    FCurrentOperation: string;
    FLog: TStringList;
    FProgress: integer;
    FRun: boolean;
    FFinished: TDateTime;
    FStartedAt: TDateTime;
    FThread: TFeatureThread;
  public
    constructor Create;
    destructor Destroy; override;
    property Run: boolean read FRun write FRun;
    property CurrentOperation: string read FCurrentOperation write FCurrentOperation;
    property Progress: integer read FProgress write FProgress;
    property LastResult: String read FLastResult write FLastResult;
    property Log: TStringList read FLog write FLog;
    property StartedAt: TDateTime read FStartedAt write FStartedAt;
    property Finished: TDateTime read FFinished write FFinished;
    property Thread: TFeatureThread read FThread write FThread;
  end;

  TFeature = class
  private
    FName: string;
    FCaption: string;
    FParams: TFeatureParamList;
    FResultType: TVarType;
    FStatus: TFeatureStatus;
    FModule: TModule;
    FLastRunParams: string;
  public
    constructor Create(Module: TModule; Info: TFeatureInfo);
    destructor Destroy; override;
    property Name: string read FName;
    property Caption: string read FCaption;
    property Params: TFeatureParamList read FParams;
    property ResultType: TVarType read FResultType;
    property LastRunParams: string read FLastRunParams write FLastRunParams;
    property Status: TFeatureStatus read FStatus write FStatus;
    procedure Run(Params: TRunParamsInfo);
    procedure Stop;
    procedure AddLog(const AMessage: string; LogKind: TLogKind);
  end;
  TFeatureList = TObjectList<TFeature>;

  TFeatureNotifyAction = (nStart, nFinish);
  TFeatureNotify = procedure(Action: TFeatureNotifyAction; Feature: TFeature) of object;
  TModule = class
  private
    FGUID: string;
    FFeatures: TFeatureList;
    FOnFeatureNotify: TFeatureNotify;
    procedure DoFeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
  public
    LibraryName: string;
    Info: TModuleInfo;
    LibHandle: THandle;

    GetFeaturesProc: TGetFeatures;
    GetFeatureInfoProc: TGetFeatureInfo;
    RegisterLogCallbackProc: TRegisterLogCallback;
    UnregisterLogCallbackProc: TUnregisterLogCallback;
    RegisterProgressCallbackProc: TRegisterProgressCallback;
    UnregisterProgressCallbackProc: TUnregisterProgressCallback;
    RunFeatureProc: TRunFeature;
    StopFeatureProc: TStopFeature;
    FreeResources: TFreeResources;

    constructor Create;
    destructor Destroy; override;
    function Init: Boolean;
    procedure FInit;
    property GUID: string read FGUID;
    property Features: TFeatureList read FFeatures;
    function FindFeature(const Name: string): TFeature;
    property OnFeatureNotify: TFeatureNotify read FOnFeatureNotify write FOnFeatureNotify;
  end;

  TModuleList = class(TObjectList<TModule>)
    function Find(const GUID: string): TModule;
    function FindFeature(const LibraryGUID, FeatureName: string): TFeature;
  end;

implementation

{ TFeature }

procedure TFeature.AddLog(const AMessage: string; LogKind: TLogKind);
begin
  // удаляем старые записи
  while Status.Log.Count > LOG_LIMIT do
    Status.Log.Delete(0);

  Status.Log.Add(AMessage);
end;

constructor TFeature.Create(Module: TModule; Info: TFeatureInfo);
var
  i: integer;
begin
  LastRunParams := '';
  FModule := Module;
  FName := string(Info.Name);
  FCaption := string(Info.Caption);
  FParams := TFeatureParamList.Create;
  FStatus := TFeatureStatus.Create;
  for I := 0 to Length(Info.Params) - 1 do
    FParams.Add(TFeatureParam.Create(Info.Params[i]));
  FResultType := Info.ResultType;
end;

destructor TFeature.Destroy;
begin
  FModule := nil;
  FParams.Free;
  FStatus.Free;
  inherited;
end;

procedure TFeature.Run(Params: TRunParamsInfo);
begin
  Status.Thread := TFeatureThread.CreateAndRun(Self, Params);
end;

procedure TFeature.Stop;
begin
  FModule.StopFeatureProc(ShortString(Name));
end;

{ TFeatureParam }

constructor TFeatureParam.Create(Info: TFeatureParamInfo);
begin
  FRequred := Info.Requred;
  FName := string(Info.Name);
  FCaption := string(Info.Caption);
  FParamType := Info.ParamType;
  FDefault := string(Info.Default);
end;

{ TModule }

constructor TModule.Create;
begin
  inherited;
  FGUID := TGUID.NewGuid.ToString;
  FFeatures := TFeatureList.Create;
end;

destructor TModule.Destroy;
begin
  FInit;
  FFeatures.Free;
  inherited;
end;

procedure TModule.DoFeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
begin
  if Assigned(FOnFeatureNotify) then
    FOnFeatureNotify(Action, Feature);
end;

function TModule.FindFeature(const Name: string): TFeature;
var
  i: integer;
begin
  result := nil;
  for I := 0 to FFeatures.Count - 1 do
    if FFeatures[i].Name = Name then
    begin
      result := FFeatures[i];
      exit;
    end;
end;

procedure TModule.FInit;
begin
  if Assigned(FreeResources) then
    FreeResources;
  if LibHandle <> 0 then
    FreeLibrary(LibHandle);
end;

function TModule.Init: Boolean;
var
  sl: TStringList;
  i: integer;
  Feature: TFeature;
begin
  result := true;
  @GetFeaturesProc := GetProcAddress(LibHandle, 'GetFeatures');
  @GetFeatureInfoProc := GetProcAddress(LibHandle, 'GetFeatureInfo');

  @RegisterLogCallbackProc := GetProcAddress(LibHandle, 'RegisterLogCallback');
  @UnregisterLogCallbackProc := GetProcAddress(LibHandle, 'UnregisterLogCallback');
  @RegisterProgressCallbackProc := GetProcAddress(LibHandle, 'RegisterProgressCallback');
  @UnregisterProgressCallbackProc := GetProcAddress(LibHandle, 'UnregisterProgressCallback');

  @RunFeatureProc := GetProcAddress(LibHandle, 'RunFeature');
  @StopFeatureProc := GetProcAddress(LibHandle, 'StopFeature');

  @FreeResources := GetProcAddress(LibHandle, 'FreeResources');

  if not Assigned(GetFeaturesProc) or
     not Assigned(GetFeatureInfoProc) or
     not Assigned(RegisterLogCallbackProc) or
     not Assigned(UnregisterLogCallbackProc) or
     not Assigned(RegisterProgressCallbackProc) or
     not Assigned(UnregisterProgressCallbackProc) or
     not Assigned(RunFeatureProc) or
     not Assigned(StopFeatureProc) or
     not Assigned(FreeResources)
    then
      exit(false);

  try
    sl := TStringList.Create;
    try
      sl.Delimiter := ',';
      sl.DelimitedText := GetFeaturesProc(ShortString(FGUID), Info);;
      for I := 0 to sl.Count - 1 do
      begin
        try
          Feature := TFeature.Create(self, GetFeatureInfoProc(ShortString(sl[i])));
        except
          exit(false);
        end;
        FFeatures.Add(Feature);
      end;
    finally
      sl.Free;
    end;
  except
    result := false;
  end;
end;

{ TFeatureStatus }

constructor TFeatureStatus.Create;
begin
  FLog := TStringList.Create;
  FThread := nil;
end;

destructor TFeatureStatus.Destroy;
begin
  FLog.Free;
  inherited;
end;

{ TFeatureThread }

constructor TFeatureThread.CreateAndRun(Feature: TFeature; Params: TRunParamsInfo);
begin
  FreeOnTerminate := true;
  FParams := Params;
  FFeature := Feature;
  FFeature.Status.FLastResult := '';
  FFeature.Status.Thread := self;
  FFeature.Status.Progress := 0;
  FFeature.Status.Run := true;
  FFeature.Status.StartedAt := Now;
  inherited Create(false);
end;

procedure TFeatureThread.DoTerminate;
begin
  FFeature.Status.Run := false;
  FFeature.Status.Finished := Now;
  FFeature.Status.Thread := nil;
  FFeature.Status.Progress := 100;
  FFeature.FModule.DoFeatureNotify(nFinish, FFeature);
end;

procedure TFeatureThread.Execute;
begin
  FFeature.FModule.DoFeatureNotify(nStart, FFeature);
  FFeature.Status.LastResult := FFeature.FModule.RunFeatureProc(ShortString(FFeature.Name), FParams);
end;

{ TModuleList }

function TModuleList.Find(const GUID: string): TModule;
var
  i: integer;
begin
  result := nil;
  for I := 0 to Count - 1 do
    if Items[i].GUID = GUID then
    begin
      result := Items[i];
      exit;
    end;
end;

function TModuleList.FindFeature(const LibraryGUID, FeatureName: string): TFeature;
var
  Module: TModule;
begin
  result := nil;
  Module := Find(LibraryGUID);
  if Assigned(Module) then
    result := Module.FindFeature(FeatureName);
end;

{ TFeatureParamList }

function TFeatureParamList.Find(const Name: string): TFeatureParam;
var
  i: integer;
begin
  result := nil;
  for i := 0 to Count - 1 do
    if Items[i].Name = Name then
    begin
      result := Items[i];
      exit;
    end;
end;

end.
