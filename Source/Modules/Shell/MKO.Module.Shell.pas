// описание второго модуля: выполнение shell-команды
unit MKO.Module.Shell;

interface

uses
  Winapi.Windows,
  Types,
  SysUtils,
  StrUtils,
  Classes,

  MKO.Types,
  MKO.Modules.Common;

type
  TFeatureType = (ftShellExec);

  TShellModule = class(TMKOModule)
  private
    FFeatures: array[TFeatureType] of TFeatureInfo;
    FStopFeatures: array[TFeatureType] of boolean;
    function ShellExecute(Params: PRunParamsInfo): string;

  protected
    function DoGetFeaturesCount: integer; override;
    function DoGetFeatureInfo(Index: integer): PFeatureInfo; override;
    function DoRunFeature(Index: integer; Params: PRunParamsInfo; out AResult: string): boolean; override;
    procedure DoStopFeature(Index: integer); override;

  public
    constructor Create; override;
  end;


implementation

{ TShellModule }

constructor TShellModule.Create;
begin
  FInfo.Caption := 'Командная строка';
  FInfo.Description := 'Командная строка';

  FFeatures[ftShellExec].SetParams('ExecuteCommand', 'Выполнить', varString);
  SetLength(FFeatures[ftShellExec].Params, 1);
  with FFeatures[ftShellExec] do
  begin
    Params[0].SetParams(true, 'Command', 'Команда', varString, '');
  end;
end;

function TShellModule.DoGetFeatureInfo(Index: integer): PFeatureInfo;
begin
  result := @FFeatures[TFeatureType(index)];
end;

function TShellModule.DoGetFeaturesCount: integer;
begin
  result := Length(FFeatures);
end;

function TShellModule.DoRunFeature(Index: integer; Params: PRunParamsInfo; out AResult: string): boolean;
begin
  result := true;
  FStopFeatures[TFeatureType(Index)] := false;
  case TFeatureType(Index) of
    ftShellExec: AResult := ShellExecute(Params);
  else
    result := false;
  end;
end;

procedure TShellModule.DoStopFeature(Index: integer);
begin
  FStopFeatures[TFeatureType(Index)] := true;
end;

function TShellModule.ShellExecute(Params: PRunParamsInfo): string;
var
  hRead, hWrite: THandle;
  sa: TSecurityAttributes;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array[0..4095] of AnsiChar;
  BytesRead: DWORD;

  Part, Output: TStringStream; // частичный временный поток для логирования вывода в консоль информации и результирующий поток
  RawBytes: TBytesStream;
  Feature: ShortString;
  Command: string;
  i: integer;
begin
  Feature := FFeatures[ftShellExec].Name;
  for i := 0 to Length(Params^) - 1 do
    case IndexText(String(Params^[i].Name), ['Command']) of
      0: Command := String(Params^[i].Value);
    end;

  Result := '';
  RawBytes := TBytesStream.Create;
  try
    // настройка безопасности для наследуемых хэндлов
    FillChar(sa, SizeOf(sa), 0);
    sa.nLength := SizeOf(TSecurityAttributes);
    sa.bInheritHandle := True;
    sa.lpSecurityDescriptor := nil;

    // ссоздаём пайп для чтения из консольки
    if not CreatePipe(hRead, hWrite, @sa, 0) then
      Exit;

    Part := TStringStream.Create('', TEncoding.GetEncoding(GetOEMCP), False);
    try
      // рекорд для запуска процесса
      FillChar(StartupInfo, SizeOf(StartupInfo), 0);
      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.hStdOutput := hWrite;
      StartupInfo.hStdError := hWrite;
      StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_HIDE;
      DoLog(Feature, '> ' + Command);
      // запускаем cmd.exe с командой
      if CreateProcess(nil,
        PChar('cmd.exe /C "' + Command + '"'),
        nil, nil, True, 0, nil, nil,
        StartupInfo, ProcessInfo)
      then
      begin
        CloseHandle(hWrite); // закрываем запись со стороны родителя

        // читаем вывод по частям
        while ReadFile(hRead, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) and (BytesRead > 0) do
        begin
          Part.Clear;
          Part.Write(Buffer, BytesRead);
          DoLog(Feature, Part.DataString);
          RawBytes.WriteBuffer(Buffer, BytesRead);
          if FStopFeatures[ftShellExec] then
            break;
        end;

        // ждём завершения процесса
        if not FStopFeatures[ftShellExec] then
          WaitForSingleObject(ProcessInfo.hProcess, INFINITE)ж

        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end;
    finally
      CloseHandle(hRead);
    end;

    // преобразуем сырые байты в строку Unicode ---
    // используем OEM-кодировку
    // GetOEMCP — возвращает OEM-кодовую страницу (866 для русского)
    Output := TStringStream.Create('', TEncoding.GetEncoding(GetOEMCP), False);
    try
      RawBytes.Position := 0;
      Output.CopyFrom(RawBytes, 0);
      Result := Output.DataString;
    finally
      Output.Free;
    end;
  except
    on E: Exception do
      Result := 'Ошибка: ' + E.Message;
  end;
  RawBytes.Free;
end;

initialization
  // регистрируем свой класс модуля
  TMKOModule.ModuleClass := TShellModule;

end.
