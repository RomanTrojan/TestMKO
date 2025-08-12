  MKO.Types,
  MKO.Modules.Common;

// возращает список доступных функций
function GetFeatures(GUID: ShortString; var Info: TModuleInfo): PChar; stdcall;
begin
  result := TMKOModule.GetInstance.GetFeatures(GUID, Info);
end;
// инфо по задаче
function GetFeatureInfo(const Feature: ShortString): TFeatureInfo; stdcall;
begin
  result := TMKOModule.GetInstance.GetFeatureInfo(Feature);
end;
// регистрация логирования
procedure RegisterLogCallback(Callback: TCallbackLog); stdcall;
begin
  TMKOModule.GetInstance.RegisterLogCallback(Callback);
end;
// отмена логирования
procedure UnregisterLogCallback; stdcall;
begin
  TMKOModule.GetInstance.UnregisterLogCallback;
end;
// регистрация уведомлений о прогрессе задачи
procedure RegisterProgressCallback(Callback: TCallbackProgress); stdcall;
begin
  TMKOModule.GetInstance.RegisterProgressCallback(Callback);
end;
// отмена регистрация уведомлений о прогрессе задачи
procedure UnregisterProgressCallback; stdcall;
begin
  TMKOModule.GetInstance.UnregisterProgressCallback;
end;
// запустить задачу
function RunFeature(const Feature: ShortString; Params: TRunParamsInfo): PChar; stdcall;
begin
  result := TMKOModule.GetInstance.RunFeature(Feature, @Params);
end;
// прервать выполнение задачи
procedure StopFeature(const Feature: ShortString); stdcall;
begin
  TMKOModule.GetInstance.StopFeature(Feature);
end;
// освобождение ресурсво DLL
procedure FreeResources;
begin
  TMKOModule.FreeResources;
end;

exports
  GetFeatures,
  GetFeatureInfo,
  RegisterLogCallback,
  UnregisterLogCallback,
  RegisterProgressCallback,
  UnregisterProgressCallback,
  RunFeature,
  StopFeature,
  FreeResources;

begin
