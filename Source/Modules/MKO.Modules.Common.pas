unit MKO.Modules.Common;

interface

uses
  Classes,
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
    function DoGetFeatureInfo(Index: integer): TFeatureInfo; virtual; abstract;
    function DoRunFeature(Index: integer): boolean; virtual; abstract;

  public
    class var ModuleClass: TMKOModuleClass;
    constructor Create; virtual;
    function GetFeatures(GUID: string; out Info: TModuleInfo): string;
    function GetFeatureInfo(const Feature: string): TFeatureInfo;
    procedure RegisterLogCallback(Callback: TCallbackLog);
    procedure UnregisterLogCallback;
    function RunFeature(const Feature: string; Params: TRunParamsInfo): boolean;
    class function GetInstance: TMKOModule;
  end;

implementation

{ TMKOModule }

constructor TMKOModule.Create;
begin
  //
end;

function TMKOModule.GetFeatureInfo(const Feature: string): TFeatureInfo;
var
  i: integer;
begin
  FillChar(result, SizeOf(result), 0);
  for i := 0 to DoGetFeaturesCount - 1 do
    if DoGetFeatureInfo(i).Name = Feature then
      result := DoGetFeatureInfo(i);
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

function TMKOModule.RunFeature(const Feature: string; Params: TRunParamsInfo): boolean;
var
  i: integer;
begin
  result := false;
  for i := 0 to DoGetFeaturesCount - 1 do
    if DoGetFeatureInfo(i).Name = Feature then
      result := DoRunFeature(i);
end;

procedure TMKOModule.UnregisterLogCallback;
begin
  FLogCallback := nil;
end;

end.
