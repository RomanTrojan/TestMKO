unit MKO.Types;

interface

type

  TFeatureParamInfo = record
    Requred: boolean;
    Name: string;
    Caption: string;
    ParamType: TVarType;
    Default: Variant;
  end;

  TFeatureParamsInfo = array of TFeatureParamInfo;

  TFeatureInfo = record
    Name: string;
    Caption: string;
    Params: TFeatureParamsInfo;
    ResultType: TVarType;
  end;

  TRunParamInfo = record
    Name: string;
    Value: Variant;
  end;

  TRunParamsInfo = TArray<TRunParamInfo>;

  TModuleInfo = record
    Description: string;
  end;

  TLogKind = (lkInfo, lkWarning, lkCritical);

  TCallbackLog = procedure(const LibraryGUID, Feature, LogMessage: string; Kind: TLogKind); stdcall;

  TGetFeatures = function(const GUID: string; out Info: TModuleInfo): string; stdcall;
  TGetFeatureInfo = function(const Feature: string): TFeatureInfo; stdcall;
  TRegisterLogCallback = procedure(Callback: TCallbackLog); stdcall;
  TUnregisterLogCallback = procedure; stdcall;
  TRunFeature = function(const Feature: string; Params: TRunParamsInfo): boolean; stdcall;

implementation

end.
