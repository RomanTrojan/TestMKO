unit MKO.Types;

interface

type

  PFeatureParamInfo = ^TFeatureParamInfo;
  TFeatureParamInfo = record
    Requred: boolean;
    Name: string;
    Caption: string;
    ParamType: TVarType;
    Default: Variant;
    procedure SetParams(
      Requred: boolean;
      Name: string;
      Caption: string;
      ParamType: TVarType;
      Default: Variant);
  end;

  TFeatureParamsInfo = array of TFeatureParamInfo;

  PFeatureInfo = ^TFeatureInfo;
  TFeatureInfo = record
    Name: string;
    Caption: string;
    Params: TFeatureParamsInfo;
    ResultType: TVarType;
    procedure SetParams(
      Name: string;
      Caption: string;
      ResultType: TVarType);
  end;

  TRunParamInfo = record
    Name: string;
    Value: Variant;
  end;

  PRunParamsInfo = ^TRunParamsInfo;
  TRunParamsInfo = TArray<TRunParamInfo>;

  TModuleInfo = record
    Caption: string;
    Description: string;
  end;

  TLogKind = (lkInfo, lkWarning, lkCritical);

  TCallbackLog = procedure(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;

  TGetFeatures = function(const GUID: string; out Info: TModuleInfo): string; stdcall;
  TGetFeatureInfo = function(const Feature: string): TFeatureInfo; stdcall;
  TRegisterLogCallback = procedure(Callback: TCallbackLog); stdcall;
  TUnregisterLogCallback = procedure; stdcall;
  TRunFeature = function(const Feature: string; Params: TRunParamsInfo): boolean; stdcall;
  TFreeResources = procedure; stdcall;

implementation

{ TFeatureParamInfo }

procedure TFeatureParamInfo.SetParams(Requred: boolean; Name, Caption: string; ParamType: TVarType; Default: Variant);
begin
  self.Requred := Requred;
  self.Name := Name;
  self.Caption := Caption;
  self.ParamType := ParamType;
  self.Default := Default;
end;

{ TFeatureInfo }

procedure TFeatureInfo.SetParams(Name, Caption: string; ResultType: TVarType);
begin
  self.Name := Name;
  self.Caption := Caption;
  self.ResultType := ResultType;
end;

end.
