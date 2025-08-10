unit MKO.Module.FileSearch;

interface

uses
  SysUtils,

  MKO.Types,
  MKO.Modules.Common;

type
  TFeatureType = (ftFindFile, ftFindByContent);

  TFileSearchModule = class(TMKOModule)
  private
    FFeatures: array[TFeatureType] of TFeatureInfo;
    function FindFiles(Params: PRunParamsInfo): boolean;
    function FindByContent(Params: PRunParamsInfo): boolean;

  protected
    function DoGetFeaturesCount: integer; override;
    function DoGetFeatureInfo(Index: integer): PFeatureInfo; override;
    function DoRunFeature(Index: integer; Params: PRunParamsInfo): boolean; override;

  public
    constructor Create; override;
  end;

implementation

{ TFileSearchModule }

constructor TFileSearchModule.Create;
begin
  FInfo.Caption := 'Файловые операции';
  FInfo.Description := 'Работа с файловой системой';

  FFeatures[ftFindFile].SetParams('FindFiles', 'Поиск файлов', varString);
  SetLength(FFeatures[ftFindFile].Params, 2);
  FFeatures[ftFindFile].Params[0].SetParams(true, 'Path', 'Путь', varString, '');
  FFeatures[ftFindFile].Params[1].SetParams(false, 'Mask', 'Маска файлов', varString, '*.*');

  //////////

  FFeatures[ftFindByContent].SetParams('FindContent', 'Поиск содержимого в файлах', varString);
  SetLength(FFeatures[ftFindByContent].Params, 2);
  FFeatures[ftFindByContent].Params[0].SetParams(true, 'Path', 'Путь', varString, '');
  FFeatures[ftFindByContent].Params[1].SetParams(true, 'Fragment', 'Фрагмент', varString, '');

  inherited Create;
end;

function TFileSearchModule.DoGetFeatureInfo(Index: integer): PFeatureInfo;
begin
  result := @FFeatures[TFeatureType(index)];
end;

function TFileSearchModule.DoGetFeaturesCount: integer;
begin
  result := Length(FFeatures);
end;

function TFileSearchModule.DoRunFeature(Index: integer; Params: PRunParamsInfo): boolean;
var
  i: integer;
  Feature: string;
begin
  case TFeatureType(Index) of
    ftFindFile:      result := FindFiles(Params);
    ftFindByContent: result := FindByContent(Params);
  end;
end;

function TFileSearchModule.FindByContent(Params: PRunParamsInfo): boolean;
var
  i: integer;
begin
  for I := 1 to 10 do
  begin
    sleep(1000);
    DoLog(FFeatures[ftFindFile].Name, 'i =' + IntToStr(i), lkInfo);
  end;
  result := true;
end;

function TFileSearchModule.FindFiles(Params: PRunParamsInfo): boolean;
var
  i: integer;
begin
  for I := 1 to 10 do
  begin
    sleep(1000);
    DoLog(FFeatures[ftFindFile].Name, 'i =' + IntToStr(i), lkInfo);
  end;
  result := true;
end;

initialization
  TMKOModule.ModuleClass := TFileSearchModule;

end.
