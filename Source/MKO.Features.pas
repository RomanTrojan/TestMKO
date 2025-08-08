unit MKO.Features;

interface

uses
  Windows,
  Classes,
  SysUtils,
  Generics.Collections,

  MKO.Types;

type
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

  TFeature = class
  private
    FName: string;
    FCaption: string;
    FParams: TFeatureParamList;
    FResultType: TVarType;
  public
    constructor Create(Info: TFeatureInfo);
    destructor Destroy; override;
    property Name: string read FName;
    property Caption: string read FCaption;
    property Params: TFeatureParamList read FParams;
    property ResultType: TVarType read FResultType;
  end;
  TFeatureList = TList<TFeature>;

  TModule = class
  private
    FGUID: string;
  public

    LibraryName: string;
    Info: TModuleInfo;
    LibHandle: THandle;

    GetFeaturesProc: TGetFeatures;
    GetFeatureInfoProc: TGetFeatureInfo;
    RegisterLogCallbackProc: TRegisterLogCallback;
    UnregisterLogCallbackProc: TUnregisterLogCallback;
    RunFeatureProc: TRunFeature;

    Features: TFeatureList;
    constructor Create;
    destructor Destroy; override;
    function Init: Boolean;
    property GUID: string read FGUID;
  end;
  TModuleList = class(TList<TModule>);

implementation

{ TFeature }

constructor TFeature.Create(Info: TFeatureInfo);
var
  i: integer;
begin
  FName := Info.Name;
  FCaption := Info.Caption;
  FParams := TFeatureParamList.Create;
  for I := 0 to Length(Info.Params) - 1 do
    FParams.Add(TFeatureParam.Create(Info.Params[i]));
  FResultType := Info.ResultType;
end;

destructor TFeature.Destroy;
begin
  FParams.Free;
  inherited;
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
        Feature := TFeature.Create(GetFeatureInfoProc(sl[i]));
      except
        exit(false);
      end;
      Features.Add(Feature);
    end;
  except
    result := false;
  end;
end;

end.
