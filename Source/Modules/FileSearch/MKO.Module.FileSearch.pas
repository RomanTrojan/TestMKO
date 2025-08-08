unit MKO.Module.FileSearch;

interface

uses
  SysUtils,

  MKO.Types,
  MKO.Modules.Common;

type
  TFileSearchModule = class(TMKOModule)
  private
    FFeatures: array of TFeatureInfo;

  protected
    function DoGetFeaturesCount: integer; override;
    function DoGetFeatureInfo(Index: integer): TFeatureInfo; override;
    function DoRunFeature(Index: integer): boolean; override;

  public
    constructor Create; override;
  end;

implementation

{ TFileSearchModule }

constructor TFileSearchModule.Create;
begin
  FInfo.Description := 'Работа с файлами';

  setLength(FFeatures, 2);

  FFeatures[0].Name := 'FindFiles';
  FFeatures[0].Caption := 'Поиск файлов';
  FFeatures[0].ResultType := varString;
  SetLength(FFeatures[0].Params, 2);

  FFeatures[0].Params[0].Requred := true;
  FFeatures[0].Params[0].Name := 'Path';
  FFeatures[0].Params[0].Caption := 'Путь';
  FFeatures[0].Params[0].ParamType := varString;
  FFeatures[0].Params[0].Default := '';

  FFeatures[0].Params[0].Requred := False;
  FFeatures[0].Params[1].Name := 'Mask';
  FFeatures[0].Params[1].Caption := 'Маска файлов';
  FFeatures[0].Params[1].ParamType := varString;
  FFeatures[0].Params[1].Default := '*.*';

  //////////

  FFeatures[1].Name := 'FindContent';
  FFeatures[1].Caption := 'Поиск содержимого в файлах';
  FFeatures[1].ResultType := varString;
  SetLength(FFeatures[1].Params, 2);

  FFeatures[1].Params[0].Requred := true;
  FFeatures[1].Params[0].Name := 'Path';
  FFeatures[1].Params[0].Caption := 'Путь';
  FFeatures[1].Params[0].ParamType := varString;
  FFeatures[1].Params[0].Default := '';

  FFeatures[1].Params[0].Requred := true;
  FFeatures[1].Params[1].Name := 'Fragment';
  FFeatures[1].Params[1].Caption := 'Фрагмент';
  FFeatures[1].Params[1].ParamType := varString;
  FFeatures[1].Params[1].Default := '';

  inherited Create;
end;

function TFileSearchModule.DoGetFeatureInfo(Index: integer): TFeatureInfo;
begin
  result := FFeatures[index];
end;

function TFileSearchModule.DoGetFeaturesCount: integer;
begin
  result := Length(FFeatures);
end;

function TFileSearchModule.DoRunFeature(Index: integer): boolean;
var
  i: integer;
  Feature: string;
begin
  Feature := FFeatures[Index].Name;

  if Assigned(FLogCallback) then
    FLogCallback(FGUID, Feature, Format('Процесс %s запущен', [Feature]), lkWarning);

  for I := 1 to 10 do
  begin
    sleep(1000);
    if Assigned(FLogCallback) then
      FLogCallback(FGUID, Feature, 'i =' + IntToStr(i), lkInfo);
  end;

  if Assigned(FLogCallback) then
    FLogCallback(FGUID, Feature, Format('Процесс %s завершен', [Feature]), lkWarning);

  result := true;
end;

initialization
  TMKOModule.ModuleClass := TFileSearchModule;

end.
