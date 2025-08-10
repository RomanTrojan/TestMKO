unit MKO.Features;

interface

uses
  Windows,
  Classes,
  SysUtils,
  Generics.Collections,

  MKO.Types;

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
    FDefault: Variant;

  public
    constructor Create(Info: TFeatureParamInfo);
    property Requred: boolean read FRequred;
    property Name: string read FName;
    property Caption: string read FCaption;
    property ParamType: TVarType read FParamType;
    property Default: Variant read FDefault;
  end;
  TFeatureParamList = TList<TFeatureParam>;

  TFeatureStatus = class
  private
    FLastResult: string;
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
    property LastResult: string read FLastResult write FLastResult;
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
  public
    constructor Create(Module: TModule; Info: TFeatureInfo);
    destructor Destroy; override;
    property Name: string read FName;
    property Caption: string read FCaption;
    property Params: TFeatureParamList read FParams;
    property ResultType: TVarType read FResultType;
    property Status: TFeatureStatus read FStatus write FStatus;
    procedure Run(Params: TRunParamsInfo);
  end;
  TFeatureList = TList<TFeature>;

  TFeatureNotifyAction = (nStart, nFinish);
  TFeatureNotify = procedure(Action: TFeatureNotifyAction; Feature: TFeature) of object;
  TModule = class
  private
    FGUID: string;
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
    RunFeatureProc: TRunFeature;
    FreeResources: TFreeResources;

    Features: TFeatureList;
    constructor Create;
    destructor Destroy; override;
    function Init: Boolean;
    property GUID: string read FGUID;
    property OnFeatureNotify: TFeatureNotify read FOnFeatureNotify write FOnFeatureNotify;
  end;
  TModuleList = class(TList<TModule>);

implementation

{ TFeature }

constructor TFeature.Create(Module: TModule; Info: TFeatureInfo);
var
  i: integer;
begin
  FModule := Module;
  FName := Info.Name;
  FCaption := Info.Caption;
  FParams := TFeatureParamList.Create;
  FStatus := TFeatureStatus.Create;
  for I := 0 to Length(Info.Params) - 1 do
    FParams.Add(TFeatureParam.Create(Info.Params[i]));
  FResultType := Info.ResultType;
end;

destructor TFeature.Destroy;
begin
  FParams.Free;
  FStatus.Free;
  inherited;
end;

procedure TFeature.Run(Params: TRunParamsInfo);
begin
  Status.Thread := TFeatureThread.CreateAndRun(Self, Params);
end;

{ TFeatureParam }

constructor TFeatureParam.Create(Info: TFeatureParamInfo);
begin
  FRequred := Info.Requred;
  FName := Info.Name;
  FCaption := Info.Caption;
  FParamType := Info.ParamType;
  FDefault := Info.Default;
end;

{ TModule }

constructor TModule.Create;
begin
  FGUID := TGUID.NewGuid.ToString;
  Features := TFeatureList.Create
end;

destructor TModule.Destroy;
begin
  Features.Free;
  inherited;
end;

procedure TModule.DoFeatureNotify(Action: TFeatureNotifyAction; Feature: TFeature);
begin
  if Assigned(FOnFeatureNotify) then
    FOnFeatureNotify(Action, Feature);
end;

function TModule.Init: Boolean;
var
  s: string;
  sl: TStringList;
  i: integer;
  Feature: TFeature;
begin
  result := true;
  @GetFeaturesProc := GetProcAddress(LibHandle, 'GetFeatures');
  @GetFeatureInfoProc := GetProcAddress(LibHandle, 'GetFeatureInfo');
  @RegisterLogCallbackProc := GetProcAddress(LibHandle, 'RegisterLogCallback');
  @UnregisterLogCallbackProc := GetProcAddress(LibHandle, 'UnregisterLogCallback');
  @RunFeatureProc := GetProcAddress(LibHandle, 'RunFeature');
  @FreeResources := GetProcAddress(LibHandle, 'FreeResources');

  if not Assigned(GetFeaturesProc) or
     not Assigned(GetFeatureInfoProc) or
     not Assigned(RegisterLogCallbackProc) or
     not Assigned(UnregisterLogCallbackProc) or
     not Assigned(RunFeatureProc) then
    exit(false);

  try
    sl := TStringList.Create;
    sl.Delimiter := ',';
    sl.DelimitedText := GetFeaturesProc(FGUID, Info);
    for I := 0 to sl.Count - 1 do
    begin
      try
        Feature := TFeature.Create(self, GetFeatureInfoProc(sl[i]));
      except
        exit(false);
      end;
      Features.Add(Feature);
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
  FFeature.FModule.RunFeatureProc(FFeature.Name, FParams);
end;

end.
