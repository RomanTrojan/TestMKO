library FileSearch;

uses
  SysUtils,
  StrUtils,

  MKO.Types,
  MKO.Modules.Common,
  MKO.Module.FileSearch;

// Возращает список доступных функций
function GetFeatures(GUID: string; out Info: TModuleInfo): string; stdcall;
begin
  result := TMKOModule.GetInstance.GetFeatures(GUID, Info);
end;

function GetFeatureInfo(const Feature: string): TFeatureInfo; stdcall;
begin
  result := TMKOModule.GetInstance.GetFeatureInfo(Feature);
end;

procedure RegisterLogCallback(Callback: TCallbackLog); stdcall;
begin
  TMKOModule.GetInstance.RegisterLogCallback(Callback);
end;

procedure UnregisterLogCallback; stdcall;
begin
  TMKOModule.GetInstance.UnregisterLogCallback;
end;

function RunFeature(const Feature: string; Params: TRunParamsInfo): boolean; stdcall;
begin
  result := TMKOModule.GetInstance.RunFeature(Feature, Params);
end;

exports
  GetFeatures,
  GetFeatureInfo,
  RegisterLogCallback,
  UnregisterLogCallback,
  RunFeature;

begin

end.

