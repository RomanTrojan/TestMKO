unit MKO.Modules.Common;

interface

uses
  Classes,
  SysUtils,

  MKO.Types;

type
  TMKOModuleClass = class of TMKOModule;

  TMKOModule = class abstract
  private
    class var FInstance: TMKOModule;
    FGUID: string;
  protected
    FLogCallback: TCallbackLog;
    FInfo: TModuleInfo;

    function DoGetFeaturesCount: integer; virtual; abstract;
    function DoGetFeatureInfo(Index: integer): PFeatureInfo; virtual; abstract;
    function DoRunFeature(Index: integer; Params: PRunParamsInfo): boolean; virtual; abstract;
    function CheckRunParam(FeatureInfo: PFeatureInfo; RunParamsInfo: PRunParamsInfo): boolean; virtual;

    procedure DoLog(const Feature, LogMessage: string; Kind: TLogKind = lkInfo);

  public
    class var ModuleClass: TMKOModuleClass;
    constructor Create; virtual;
    function GetFeatures(GUID: string; out Info: TModuleInfo): string;
    function GetFeatureInfo(const Feature: string): TFeatureInfo;
    procedure RegisterLogCallback(Callback: TCallbackLog);
    procedure UnregisterLogCallback;
    function RunFeature(const Feature: string; Params: PRunParamsInfo): boolean;
    class function GetInstance: TMKOModule;
    class procedure FreeResources;
  end;

implementation

{ TMKOModule }

function TMKOModule.CheckRunParam(FeatureInfo: PFeatureInfo; RunParamsInfo: PRunParamsInfo): boolean;

  function HasRunParam(const Param: string): boolean;
  var
    i: integer;
  begin
    result := false;
    for i := 0 to Length(RunParamsInfo^) - 1 do
      if RunParamsInfo^[i].Name = Param then
        exit(true);
  end;

var
  i: integer;
begin
  result := true;
  with FeatureInfo^ do
    for I := 0 to Length(Params) - 1 do
      if Params[i].Requred and not HasRunParam(Params[i].Name) then
      begin
        DoLog(Name, Format('Отсутствует обязательный параметр "%s"', [Params[i].Name]), lkWarning);
        exit(false);
      end;
end;

constructor TMKOModule.Create;
begin
  //
end;

procedure TMKOModule.DoLog(const Feature, LogMessage: string; Kind: TLogKind);
begin
  if Assigned(FLogCallback) then
    FLogCallback(FGUID, Feature, LogMessage, Kind);
end;

class procedure TMKOModule.FreeResources;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

function TMKOModule.GetFeatureInfo(const Feature: string): TFeatureInfo;
var
  i: integer;
begin
  FillChar(result, SizeOf(result), 0);
  for i := 0 to DoGetFeaturesCount - 1 do
    if DoGetFeatureInfo(i)^.Name = Feature then
      result := DoGetFeatureInfo(i)^;
end;

function TMKOModule.GetFeatures(GUID: string; out Info: TModuleInfo): string;
var
  i: integer;
  sl: TStringList;
begin
  FGUID := GUID;
  Info := FInfo;
  sl := TStringList.Create;
  try
    sl.Delimiter := ',';
    for i := 0 to DoGetFeaturesCount - 1 do
      sl.Add(DoGetFeatureInfo(i).Name);
    result := sl.DelimitedText;
  finally
    sl.Free;
  end;
end;

class function TMKOModule.GetInstance: TMKOModule;
begin
  if not Assigned(FInstance) then
    FInstance := ModuleClass.Create;
  result := FInstance;
end;

procedure TMKOModule.RegisterLogCallback(Callback: TCallbackLog);
begin
  FLogCallback := Callback;
end;

function TMKOModule.RunFeature(const Feature: string; Params: PRunParamsInfo): boolean;
var
  i: integer;
  Info: PFeatureInfo;
begin
  result := false;
  for i := 0 to DoGetFeaturesCount - 1 do
  begin
    Info := DoGetFeatureInfo(i);
    if Info.Name = Feature then
    begin
      if CheckRunParam(Info, Params) then
      begin
        DoLog(Feature, Format('Задача "%s" запущена', [Info.Caption]));
        try
          result := DoRunFeature(i, Params);
        except
          on E: Exception do
          begin
            result := false;
            DoLog(Feature, Format('Исключение при выполнении хадачи с классом "%s", сообщение: "%s"', [E.ClassName, E.Message]), lkCritical);
          end;
        end;
        if result then
          DoLog(Feature, Format('Задача "%s" вылолнена', [Info.Caption]));
      end;
    end;
  end;
end;

procedure TMKOModule.UnregisterLogCallback;
begin
  FLogCallback := nil;
end;

end.
