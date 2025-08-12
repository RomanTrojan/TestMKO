// описание базового объекта для модулей, реальзует общие механизмы
unit MKO.Modules.Common;

interface

uses
  Classes,
  SysUtils,

  MKO.Types;

type
  // класс экземпляра объекта модуля
  TMKOModuleClass = class of TMKOModule;

  TMKOModule = class abstract
  private
    class var FInstance: TMKOModule;
    FGUID: ShortString;
  protected
    // каллбаки для передачи извежений в приложение
    FLogCallback: TCallbackLog;
    FProgressCallback: TCallbackProgress;
    // информация о модуле
    FInfo: TModuleInfo;
    // функции, необходимые для переопределения в модулях
    // получение списка доступных задач
    function DoGetFeaturesCount: integer; virtual; abstract;
    // получение описания задачи
    function DoGetFeatureInfo(Index: integer): PFeatureInfo; virtual; abstract;
    // запуск задачи
    function DoRunFeature(Index: integer; Params: PRunParamsInfo; out AResult: string): boolean; virtual; abstract;
    // осиановка задачи
    procedure DoStopFeature(Index: integer); virtual; abstract;

    // проверка входных параметров перед запуском задачи, проверяет наличие обязательных параметров
    // при необходимости - перекрыть
    function CheckRunParam(FeatureInfo: PFeatureInfo; RunParamsInfo: PRunParamsInfo): boolean; virtual;

    // вызывать в модулях для передачи извещений приложению
    procedure DoLog(const Feature: ShortString; const LogMessage: string; Kind: TLogKind = lkInfo);
    procedure DoProgress(const Feature: ShortString; const CurrentOperation: string; Progress: integer);

  public
    // класс экземпляра модуля
    class var ModuleClass: TMKOModuleClass;
    constructor Create; virtual;
    destructor Destroy; override;

    // реализация функций, опубликованных в DLL
    function GetFeatures(GUID: ShortString; out Info: TModuleInfo): PChar;
    function GetFeatureInfo(const Feature: ShortString): TFeatureInfo;
    procedure RegisterLogCallback(Callback: TCallbackLog);
    procedure UnregisterLogCallback;
    procedure RegisterProgressCallback(Callback: TCallbackProgress);
    procedure UnregisterProgressCallback;
    function RunFeature(const Feature: ShortString; Params: PRunParamsInfo): PChar;
    procedure StopFeature(const Feature: ShortString);

    // получить/создать экземпляр класса текущего модуля
    class function GetInstance: TMKOModule;
    // освободить ресурсы DLL
    class procedure FreeResources;
  end;

implementation

{ TMKOModule }

function TMKOModule.CheckRunParam(FeatureInfo: PFeatureInfo; RunParamsInfo: PRunParamsInfo): boolean;

  function HasRunParam(const Param: ShortString): boolean;
  var
    i: integer;
  begin
    result := false;
    for i := 0 to Length(RunParamsInfo^) - 1 do
      if RunParamsInfo^[i].Name = ShortString(Param) then
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
        DoLog(Name, Format('Отсутствует обязательный параметр "%s"', [Params[i].Caption]), lkWarning);
        exit(false);
      end;
end;

constructor TMKOModule.Create;
begin
  //
end;

destructor TMKOModule.Destroy;
begin
  inherited;
end;

procedure TMKOModule.DoLog(const Feature: ShortString; const LogMessage: string; Kind: TLogKind);
begin
  if Assigned(FLogCallback) then
    FLogCallback(FGUID, Feature, ShortString(LogMessage), Kind);
end;

procedure TMKOModule.DoProgress(const Feature: ShortString; const CurrentOperation: string; Progress: integer);
begin
  if Assigned(FProgressCallback) then
    FProgressCallback(FGUID, Feature, ShortString(CurrentOperation), Progress);
end;

class procedure TMKOModule.FreeResources;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

function TMKOModule.GetFeatureInfo(const Feature: ShortString): TFeatureInfo;
var
  i: integer;
begin
  FillChar(result, SizeOf(result), 0);
  for i := 0 to DoGetFeaturesCount - 1 do
    if DoGetFeatureInfo(i)^.Name = Feature then
      result := DoGetFeatureInfo(i)^;
end;

// собираем имена поддерживаемых задач через запятую
function TMKOModule.GetFeatures(GUID: ShortString; out Info: TModuleInfo): PChar;
var
  i: integer;
  sl: TStringList;
  s: string;
begin
  FGUID := GUID;
  Info := FInfo;
  sl := TStringList.Create;
  try
    sl.Delimiter := ',';
    for i := 0 to DoGetFeaturesCount - 1 do
      sl.Add(String(DoGetFeatureInfo(i).Name));
     s := sl.DelimitedText;
     result := @s[1];
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

procedure TMKOModule.RegisterProgressCallback(Callback: TCallbackProgress);
begin
  FProgressCallback := Callback;
end;

// главная функция - запуск задачи.
// перед запуском проверяем входные параметры, обрамляем запуск и завершение задачи логами
function TMKOModule.RunFeature(const Feature: ShortString; Params: PRunParamsInfo): PChar;
var
  i: integer;
  Info: PFeatureInfo;
  res: boolean;
  s: string;
begin
  result := nil;
  res := false;
  for i := 0 to DoGetFeaturesCount - 1 do
  begin
    Info := DoGetFeatureInfo(i);
    if Info.Name = Feature then
    begin
      if CheckRunParam(Info, Params) then
      begin
        DoLog(Feature, Format('Задача "%s" запущена', [Info.Caption]));
        try
          res := DoRunFeature(i, Params, s);
          result := @s[1];
        except
          on E: Exception do
          begin
            res := false;
            DoLog(Feature, Format('Исключение при выполнении задачи с классом "%s", сообщение: "%s"', [E.ClassName, E.Message]), lkCritical);
          end;
        end;
        if res then
          DoLog(Feature, Format('Задача "%s" вылолнена', [Info.Caption]));
        break;
      end;
    end;
  end;
end;

// завершение задачи. в дочерних классах модулей выставляются соответствующие флажки
procedure TMKOModule.StopFeature(const Feature: ShortString);
var
  i: integer;
  Info: PFeatureInfo;
begin
  for i := 0 to DoGetFeaturesCount - 1 do
  begin
    Info := DoGetFeatureInfo(i);
    if Info.Name = Feature then
    begin
      DoLog(Feature, Format('Завершение задачи "%s"', [Info.Caption]));
      DoStopFeature(i);
      break;
    end;
  end;
end;

procedure TMKOModule.UnregisterLogCallback;
begin
  FLogCallback := nil;
end;

procedure TMKOModule.UnregisterProgressCallback;
begin
  FProgressCallback := nil;
end;

end.
