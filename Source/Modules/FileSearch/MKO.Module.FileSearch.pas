// �������� ������� ������: ������ ������
unit MKO.Module.FileSearch;

interface

uses
  Types,
  SysUtils,
  IOUTils,
  StrUtils,
  Classes,
  Math,

  MKO.Types,
  MKO.Modules.Common;

type
  TFeatureType = (ftFindFile, ftFindByContent);

  TFileSearchModule = class(TMKOModule)
  private
    // �������� �����
    FFeatures: array[TFeatureType] of TFeatureInfo;
    // ������ ���������� ���������� �����
    FStopFeatures: array[TFeatureType] of boolean;
    // ���� ������� ������ ������ � �������� �� ���������� � ������ ���������� � AResult
    // ����� ������ � ������������ ����� � ������������ ������������ ������ � ��������� � �������� ���� ������
    function FindFiles(Params: PRunParamsInfo; out AResult: string): boolean;
    // ����� ������, � ������� ���������� ������������ ��������, ������������ ������ ����� ������� � �������� �����
    function FindByContent(Params: PRunParamsInfo; out AResult: string): boolean;

  protected
    // ����������� ������������ ���������� ������
    function DoGetFeaturesCount: integer; override;
    function DoGetFeatureInfo(Index: integer): PFeatureInfo; override;
    function DoRunFeature(Index: integer; Params: PRunParamsInfo; out AResult: string): boolean; override;
    procedure DoStopFeature(Index: integer); override;

  public
    constructor Create; override;
  end;

implementation

{ TFileSearchModule }

constructor TFileSearchModule.Create;
begin
  FInfo.Caption := '�������� ��������';
  FInfo.Description := '������ � �������� ��������';

  FFeatures[ftFindFile].SetParams('FindFiles', '����� ������', varString);
  SetLength(FFeatures[ftFindFile].Params, 3);
  with FFeatures[ftFindFile] do
  begin
    Params[0].SetParams(true, 'Path', '����', varString, '');
    Params[1].SetParams(false, 'Mask', '����� ������', varString, '*.*');
    Params[2].SetParams(false, 'Recursive', '� ����������', varBoolean, '0');
  end;

  FFeatures[ftFindByContent].SetParams('FindContent', '����� ����������� � ������', varString);
  SetLength(FFeatures[ftFindByContent].Params, 4);
  with FFeatures[ftFindByContent] do
  begin
    Params[0].SetParams(true, 'Path', '����', varString, '');
    Params[1].SetParams(false, 'Mask', '����� ������', varString, '*.*');
    Params[2].SetParams(true, 'Fragment', '��������', varString, '');
    Params[3].SetParams(false, 'Recursive', '� ����������', varBoolean, '0');
  end;

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

function TFileSearchModule.DoRunFeature(Index: integer; Params: PRunParamsInfo; out AResult: string): boolean;
begin
  result := false;
  FStopFeatures[TFeatureType(Index)] := false;
  case TFeatureType(Index) of
    ftFindFile:      result := FindFiles(Params, AResult);
    ftFindByContent: result := FindByContent(Params, AResult);
  end;
end;

procedure TFileSearchModule.DoStopFeature(Index: integer);
begin
  FStopFeatures[TFeatureType(Index)] := true;
end;

function TFileSearchModule.FindByContent(Params: PRunParamsInfo; out AResult: string): boolean;
var
  Feature: ShortString;
  Directory, Mask: string;
  Recursive: boolean;

  function FindBinaryPatternInFiles(const SearchPattern: TBytes): TStringList;
  const
    BufferSize = 4096;
  var
    // ��� ������ ����������� � �����
    Buffer: TBytes;
    OverlapBuffer: TBytes;
    BytesRead: Integer;
    BufferPos, MatchPos: Integer;
    PatternLen: Integer;
    CurrentFilePos: Int64;
    PrevBytes: TBytes;
    PrevCount: Integer;
    // ����� ��� ������
    Files: TStringDynArray;
    FilePath: string;
    FileStream: TFileStream;
    // ��� ���������� ����������
    AbsolutePos: integer;
    Positions: array of integer;
    s: string;
    i: integer;
    // ��� ���������
    CurFileCount, Progress, CurProgress: integer;
  begin
    result := TStringList.Create;

    if (Length(SearchPattern) = 0) or not TDirectory.Exists(Directory) then
      Exit;

    PatternLen := Length(SearchPattern);

    if Recursive then
      Files := TDirectory.GetFiles(Directory, Mask, TSearchOption.soAllDirectories)
    else
      Files := TDirectory.GetFiles(Directory, Mask);

    Progress := 0;
    CurFileCount := 0;
    for FilePath in Files do
    begin
      if FStopFeatures[ftFindByContent] then exit;

      Inc(CurFileCount);
      CurProgress := Trunc(CurFileCount / Length(Files) * 100);
      if Progress <> CurProgress then
      begin
        Progress := CurProgress;
        DoProgress(Feature, Format('��������� ����� "%s"', [FilePath]), Progress);
        DoLog(Feature, Format('��������� %d ������', [CurFileCount]));
      end;

      SetLength(Positions, 0);
      try
        FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
        try
          SetLength(Buffer, BufferSize);
          SetLength(PrevBytes, PatternLen - 1);
          PrevCount := 0;
          CurrentFilePos := 0;

          while FileStream.Position < FileStream.Size do
          begin
            BytesRead := FileStream.Read(Buffer[0], BufferSize);
            if BytesRead <= 0 then
              Continue;

            SetLength(OverlapBuffer, PrevCount + BytesRead);
            if PrevCount > 0 then
              Move(PrevBytes[0], OverlapBuffer[0], PrevCount);
            Move(Buffer[0], OverlapBuffer[PrevCount], BytesRead);

            for BufferPos := 0 to Length(OverlapBuffer) - PatternLen do
            begin
              MatchPos := 0;
              while (MatchPos < PatternLen) and (OverlapBuffer[BufferPos + MatchPos] = SearchPattern[MatchPos]) do
                Inc(MatchPos);

              // ��������� ���������� ������� � ����� � ��������� � � ������
              if MatchPos = PatternLen then
              begin
                AbsolutePos := CurrentFilePos + BufferPos - PrevCount;
                SetLength(Positions, Length(Positions) + 1);
                Positions[High(Positions)] := AbsolutePos;
              end;
            end;

            PrevCount := Min(PatternLen - 1, BytesRead);
            if PrevCount > 0 then
              Move(Buffer[BytesRead - PrevCount], PrevBytes[0], PrevCount);

            Inc(CurrentFilePos, BytesRead - (PatternLen - 1));
            if CurrentFilePos < 0 then
              CurrentFilePos := 0;

            if FStopFeatures[ftFindByContent] then
              break;
          end;

          // ��������� ������� � ���������
          if Length(Positions) > 0 then
          begin
            s := Format('%s (%d): ', [FilePath, Length(Positions)]);
            for i := 0 to Length(Positions) - 1 do
              if i = 0 then
                s := s + IntToStr(Positions[i])
              else
                s := s + ',' + IntToStr(Positions[i]);
            result.Add(s);
          end;
        finally
          FileStream.Free;
        end;
      except
        // ���������� ����������� �����
      end;
    end;
  end;

var
  i: integer;
  Pattern: TBytes;
  Fragment: AnsiString;
  sl: TStringList;
begin
  Feature := FFeatures[ftFindByContent].Name;
  // ����� ������� ���������
  for i := 0 to Length(Params^) - 1 do
    case IndexText(String(Params^[i].Name), ['Path', 'Mask', 'Recursive', 'Fragment']) of
      0: Directory := String(Params^[i].Value);
      1: Mask := String(Params^[i].Value);
      2: Recursive := Params^[i].Value = '1';
      3: Fragment := AnsiString(Params^[i].Value);
    end;

  // ��������� �����
  SetLength(Pattern, Length(Fragment));
  Move(Fragment[1], Pattern[0], Length(Fragment));
  sl := FindBinaryPatternInFiles(Pattern);

  // ������� ���������
  result := true;
  AResult := Format('������� %d ������: ', [sl.Count]) + sLineBreak + sl.Text;
end;

function TFileSearchModule.FindFiles(Params: PRunParamsInfo; out AResult: string): boolean;
var
  Feature: ShortString;
  Recursive: boolean;
  Mask: string;
  TotalDirCount, CurDirCount, CurProgress, Progress: integer;

  function GetFileList(const Directory: string; AddDir: boolean): TStringList;
  var
    SearchRec: TSearchRec;
    SubDir: string;
  begin
    if not AddDir then
    begin
      Inc(CurDirCount);
      CurProgress := Trunc(CurDirCount / TotalDirCount * 100);
      if Progress <> CurProgress then
      begin
        Progress := CurProgress;
        DoProgress(Feature, Format('��������� ����� "%s"', [Directory]), Progress);
        DoLog(Feature, Format('��������� %d �����', [CurDirCount]));
      end;
    end;

    Result := TStringList.Create;
    Result.Sorted := False;
    Result.Duplicates := dupIgnore;

    if not DirectoryExists(Directory) then
      Exit;

    if AddDir then
      Result.Add(Directory)
    else
      if FindFirst(IncludeTrailingPathDelimiter(Directory) + Mask, faAnyFile, SearchRec) = 0 then
      begin
        try
          repeat
            if FStopFeatures[ftFindFile] then
              exit;
            if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
              Continue;
            SubDir := Directory + PathDelim + SearchRec.Name;
            if (SearchRec.Attr and faDirectory) = 0 then
              Result.Add(SubDir);
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;

    if Recursive then
      if FindFirst(IncludeTrailingPathDelimiter(Directory) + '*.*', faAnyFile, SearchRec) = 0 then
      begin
        try
          repeat
            if FStopFeatures[ftFindFile] then exit;
            if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
              Continue;
            SubDir := IncludeTrailingPathDelimiter(Directory) + SearchRec.Name;
            if (SearchRec.Attr and faDirectory) <> 0 then
              Result.AddStrings(GetFileList(SubDir, AddDir));
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;
  end;

var
  i: integer;
  Directory: string;
  sl: TStringList;

begin
  Feature := FFeatures[ftFindFile].Name;
  // ����� ������� ���������
  for i := 0 to Length(Params^) - 1 do
    case IndexText(String(Params^[i].Name), ['Path', 'Mask', 'Recursive']) of
      0: Directory := String(Params^[i].Value);
      1: Mask := String(Params^[i].Value);
      2: Recursive := Params^[i].Value = '1';
    end;
  // ������ �������� �������� ������ ������ �����, ��� ������� ���������� ������ (������, �� ��� ����������� ���������� ������)
  sl := GetFileList(Directory, true);
  TotalDirCount := sl.Count;
  CurDirCount := 0;
  Progress := 0;
  // �������� ������ ������
  sl := GetFileList(Directory, false);

  // ������� ���������
  result := true;
  AResult := Format('������� %d ������:', [sl.Count]) + sLineBreak + sl.Text;
end;

initialization
  // ������������ ���� ����� ������
  TMKOModule.ModuleClass := TFileSearchModule;

end.
