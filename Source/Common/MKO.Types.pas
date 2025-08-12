// ���� ������, ������������ ��� ������ � DLL
unit MKO.Types;

interface

type

  // �������� ���������� ������
  PFeatureParamInfo = ^TFeatureParamInfo;
  TFeatureParamInfo = record
    Requred: boolean;
    Name: ShortString;
    Caption: ShortString;
    ParamType: TVarType;
    Default: ShortString;
    procedure SetParams(
      Requred: boolean;
      Name: ShortString;
      Caption: ShortString;
      ParamType: TVarType;
      Default: ShortString);
  end;
  TFeatureParamsInfo = array of TFeatureParamInfo;

  // �������� ������
  PFeatureInfo = ^TFeatureInfo;
  TFeatureInfo = record
    Name: ShortString;
    Caption: ShortString;
    Params: TFeatureParamsInfo;
    ResultType: TVarType;
    procedure SetParams(
      Name: ShortString;
      Caption: ShortString;
      ResultType: TVarType);
  end;

  // �������� ������� ����������, ��� ������� ������
  PRunParamsInfo = ^TRunParamsInfo;
  TRunParamInfo = record
    Name: ShortString;
    Value: ShortString;
  end;
  TRunParamsInfo = TArray<TRunParamInfo>;

  // �������� ������(DLL)
  PModuleInfo = ^TModuleInfo;
  TModuleInfo = packed record
    Caption: ShortString;
    Description: ShortString;
  end;

  // �������-�������, ��������������� ��� �������� � ���������� ��������� � ���� ���������� ������
  TLogKind = (lkInfo, lkWarning, lkCritical);
  TCallbackLog = procedure(const LibraryGUID, Feature, LogMessage: ShortString; Kind: TLogKind); stdcall;
  // �������-�������, ��������������� ��� ����������� ���������� �� ��������� ������� ���������� ������
  TCallbackProgress = procedure(const LibraryGUID, Feature, CurrentOperation: ShortString; Progress: integer); stdcall;

  // ������ ������, ��������� � DLL
  TGetFeatures = function(const GUID: ShortString; var Info: TModuleInfo): PChar; stdcall;
  TGetFeatureInfo = function(const Feature: ShortString): TFeatureInfo; stdcall;
  TRegisterLogCallback = procedure(Callback: TCallbackLog); stdcall;
  TUnregisterLogCallback = procedure; stdcall;
  TRegisterProgressCallback = procedure(Callback: TCallbackProgress); stdcall;
  TUnregisterProgressCallback = procedure; stdcall;
  TRunFeature = function(const Feature: ShortString; Params: TRunParamsInfo): PChar; stdcall;
  TStopFeature = procedure(const Feature: ShortString); stdcall;
  TFreeResources = procedure; stdcall;

implementation

{ TFeatureParamInfo }

procedure TFeatureParamInfo.SetParams(Requred: boolean; Name, Caption: ShortString; ParamType: TVarType; Default: ShortString);
begin
  self.Requred := Requred;
  self.Name := Name;
  self.Caption := Caption;
  self.ParamType := ParamType;
  self.Default := Default;
end;

{ TFeatureInfo }

procedure TFeatureInfo.SetParams(Name, Caption: ShortString; ResultType: TVarType);
begin
  self.Name := Name;
  self.Caption := Caption;
  self.ResultType := ResultType;
end;

end.
