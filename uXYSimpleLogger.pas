{
  ��ͨ����־
}
unit uXYSimpleLogger;

interface

uses Windows, Classes, SysUtils, StdCtrls, Messages, System.StrUtils,
  System.Contnrs,cxMemo;

const
  WRITE_LOG_FLAG = 'xylog\'; // ��¼��־Ĭ��Ŀ¼
  WRITE_LOG_FORMAT_DATE = 'yyyy-mm-dd'; // ����
  WRITE_LOG_FORMAT_TIME = 'hh:nn:ss.zzz'; // ʱ��
  SHOW_LOG_ADD_TIME = True; // ��־��ʾ�����Ƿ����ʱ��
  SHOW_LOG_TIME_FORMAT = 'yyyy/mm/dd hh:nn:ss.zzz'; // ��־��ʾ���ʱ��ĸ�ʽ
  SHOW_LOG_CLEAR_COUNT = 1000; // ��־��ʾ���������ʾ����
  Suffix_name = '.txt'; //��׺����


type
  TLogLevel = (LL_Info,LL_Notice,LL_Warning,LL_Error);
type
  TXYSimpleLogger = class
  private
    FCSLock: TRTLCriticalSection; // �ٽ���
    // FFileStream: TFileStream; //�ļ���
    FLogShower: TComponent; // ��־��ʾ����
    FLogDir: AnsiString; // ��־Ŀ¼
    FLogName: AnsiString; // ��־����
    FLogFlag: AnsiString; // ��־��ʶ
    FLogFileCout: Integer; //��������
  protected
    procedure ShowLog(Log: AnsiString; const LogLevel: TLogLevel = LL_Info);
    procedure NewWriteTxt(filename: string; str: string);
    procedure OpenWriteTxt(filename: string; str: string);
    { *******������չ�������ļ����µ��ļ�************* }
    procedure EnumFileInQueue(path: PAnsiChar; fileExt: string; fileList: TStringList);
    procedure log_del;// ɾ�����ڵ���־�ļ�
  public
    procedure WriteLog(Log: AnsiString; const LogLevel: TLogLevel = LL_Info); overload;

    constructor Create(LogFlag: AnsiString; LogDir: AnsiString = '')overload;
    constructor Create(LogFlag: AnsiString; LogDir: AnsiString;LogCount:Integer)overload;
    destructor Destroy; override;

     property LogFlag:AnsiString read FLogFlag write FLogFlag;
     property LogName:AnsiString read FLogName write FLogName;
     property LogFileCout:Integer read FLogFileCout write FLogFileCout;
     property LogShower: TComponent read FLogShower write FLogShower;
  end;
var
  Log:TXYSimpleLogger;

implementation

{ TXYSimpleLogger }

constructor TXYSimpleLogger.Create(LogFlag: AnsiString; LogDir: AnsiString);
begin
  Create(LogFlag,LogDir,365);
//  // InitializeCriticalSection(FCSLock);
//  if Trim(LogDir) = '' then
//    FLogDir := ExtractFilePath(ParamStr(0))
//  else
//    FLogDir := LogDir;
//  if Trim(LogFlag) = '' then
//    FLogFlag := WRITE_LOG_FLAG
//  else
//    FLogFlag := LogFlag;
//  if Copy(FLogFlag, Length(FLogFlag), 1) <> '\' then
//    FLogFlag := FLogFlag + '\';
//
//  FLogDir := FLogDir + FLogFlag;
//  FLogName := LogFlag;
//  FLogFileCout := 365;
//
//  if not DirectoryExists(FLogDir) then
//    if not ForceDirectories(FLogDir) then
//    begin
//      raise Exception.Create('��־·��������־������ܱ�����');
//    end;
//  log_del;
end;

constructor TXYSimpleLogger.Create(LogFlag, LogDir: AnsiString;
  LogCount: Integer);
begin
  if Trim(LogDir) = '' then
    FLogDir := ExtractFilePath(ParamStr(0))
  else
    FLogDir := LogDir;
  if Trim(LogFlag) = '' then
    FLogFlag := WRITE_LOG_FLAG
  else
    FLogFlag := LogFlag;
  if Copy(FLogFlag, Length(FLogFlag), 1) <> '\' then
    FLogFlag := FLogFlag + '\';

  FLogDir := FLogDir + FLogFlag;
  FLogName := LogFlag;
  FLogFileCout := LogCount;

  if not DirectoryExists(FLogDir) then
    if not ForceDirectories(FLogDir) then
    begin
      raise Exception.Create('��־·��������־������ܱ�����');
    end;
  log_del;
end;

destructor TXYSimpleLogger.Destroy;
begin
  // DeleteCriticalSection(FCSLock);
  inherited;
end;

procedure TXYSimpleLogger.EnumFileInQueue(path: PAnsiChar; fileExt: string;
  fileList: TStringList);
var
  searchRec: TSearchRec;
  found: Integer;
  tmpStr: string;
  curDir: string;
  dirs: TQueue;
  pszDir: PAnsiChar;
begin
  dirs := TQueue.Create; // ����Ŀ¼����
  dirs.Push(path); // ����ʼ����·�����
  pszDir := dirs.Pop;
  curDir := StrPas(pszDir); // ����
  { ��ʼ����,ֱ������Ϊ��(��û��Ŀ¼��Ҫ����) }
  while (True) do
  begin
    // ����������׺,�õ�����'c:\*.*' ��'c:\windows\*.*'������·��
    tmpStr := curDir + '\*.*';
    // �ڵ�ǰĿ¼���ҵ�һ���ļ�����Ŀ¼
    found := FindFirst(tmpStr, faAnyFile, searchRec);
    while found = 0 do // �ҵ���һ���ļ���Ŀ¼��
    begin
      // ����ҵ����Ǹ�Ŀ¼
      if (searchRec.Attr and faDirectory) <> 0 then
      begin
        { �������Ǹ�Ŀ¼(C:\��D:\)�µ���Ŀ¼ʱ�����'.','..'��"����Ŀ¼"
          ����Ǳ�ʾ�ϲ�Ŀ¼���²�Ŀ¼�ɡ�����Ҫ���˵��ſ��� }
        if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
        begin
          { ���ڲ��ҵ�����Ŀ¼ֻ�и�Ŀ¼��������Ҫ�����ϲ�Ŀ¼��·��
            searchRec.Name = 'Windows';
            tmpStr:='c:\Windows';
            �Ӹ��ϵ��һ�������
          }
          tmpStr := curDir + '\' + searchRec.Name;
          { ����������Ŀ¼��ӡ����������š�
            ��ΪTQueue���������ֻ����ָ��,����Ҫ��stringת��ΪPChar
            ͬʱʹ��StrNew������������һ���ռ�������ݣ������ʹ�Ѿ���
            ����е�ָ��ָ�򲻴��ڻ���ȷ������(tmpStr�Ǿֲ�����)�� }
          dirs.Push(StrNew(PChar(tmpStr)));
        end;
      end
      else // ����ҵ����Ǹ��ļ�
      begin
        { Result��¼�����������ļ���������������CreateThread�����߳�
          �����ú����ģ���֪����ô�õ��������ֵ�������Ҳ�����ȫ�ֱ��� }
        // ���ҵ����ļ��ӵ�Memo�ؼ�
        if fileExt = '.*' then
          fileList.Add(curDir + '\' + searchRec.Name)
        else
        begin
          if SameText(RightStr(curDir + '\' + searchRec.Name, Length(fileExt)),
            fileExt) then
            fileList.Add(curDir + '\' + searchRec.Name);
        end;
      end;
      // ������һ���ļ���Ŀ¼
      found := FindNext(searchRec);
    end;
    { ��ǰĿ¼�ҵ������������û�����ݣ����ʾȫ���ҵ��ˣ�
      ������ǻ�����Ŀ¼δ���ң�ȡһ�������������ҡ� }
    if dirs.Count > 0 then
    begin
      pszDir := dirs.Pop;
      curDir := StrPas(pszDir);
      StrDispose(pszDir);
    end
    else
      break;
  end;
  // �ͷ���Դ
  dirs.Free;
  FindClose(searchRec);
end;

procedure TXYSimpleLogger.log_del;
var
  fileNameList: TStringList;
begin
  fileNameList := TStringList.Create;
  try
    if FLogFileCout > 0 then
    begin
      EnumFileInQueue(PAnsiChar(FLogDir), Suffix_name, fileNameList);
      fileNameList.Sort;
      while fileNameList.Count > FLogFileCout do
      begin
        DeleteFile(PChar(fileNameList[0]));
        WriteLog('DelLogFiel:' + fileNameList[0],TLogLevel.LL_Notice);
        fileNameList.Delete(0);
      end;
    end;
  finally
    fileNameList.Free;
  end;
end;

procedure TXYSimpleLogger.NewWriteTxt(filename, str: string);
var
  F: Textfile;
begin
  AssignFile(F, filename); { Assigns the Filename }
  ReWrite(F); { Create a new file named ek.txt }
  Writeln(F, str);
  Closefile(F); { Closes file F }
end;

procedure TXYSimpleLogger.OpenWriteTxt(filename, str: string);
var
  F: Textfile;
begin
  AssignFile(F, filename); { Assigns the Filename }
  // ReWrite(F);
  Append(F); { Opens the file for editing }
  Writeln(F, str);
  Closefile(F); { Closes file F }
end;

procedure TXYSimpleLogger.ShowLog(Log: AnsiString; const LogLevel: TLogLevel);
var
  lineCount: Integer;
begin
  if FLogShower = nil then
    Exit;
  if (FLogShower is TMemo) then
  begin
    if SHOW_LOG_ADD_TIME then
      Log := FormatDateTime(SHOW_LOG_TIME_FORMAT, Now) + ' ' + Log;
    lineCount := TMemo(FLogShower).Lines.Add(Log);
    // ���������һ��
    SendMessage(TMemo(FLogShower).Handle, WM_VSCROLL, SB_LINEDOWN, 0);
    if lineCount >= SHOW_LOG_CLEAR_COUNT then
      TMemo(FLogShower).Clear;
  end
  else
  if (FLogShower is TcxMemo) then
  begin
    if SHOW_LOG_ADD_TIME then
      Log := FormatDateTime(SHOW_LOG_TIME_FORMAT, Now) + ' ' + Log;
    lineCount := TcxMemo(FLogShower).Lines.Add(Log);
    // ���������һ��
    SendMessage(TcxMemo(FLogShower).Handle, WM_VSCROLL, SB_LINEDOWN, 0);
    if lineCount >= SHOW_LOG_CLEAR_COUNT then
      TcxMemo(FLogShower).Clear;
  end
  else
    raise Exception.Create('��־�������Ͳ�֧��:' + FLogShower.ClassName);
end;

procedure TXYSimpleLogger.WriteLog(Log: AnsiString; const LogLevel: TLogLevel);
var
  ACompleteFileName: string;
  TmpValue,LogValue: AnsiString;
begin
//  if not IniOptions.systemifLog then Exit;

  // EnterCriticalSection(FCSLock);
  LogValue := Log;
  try
    case LogLevel of
      TLogLevel.LL_Info:
        LogValue := '[Infor] ' + LogValue;
      TLogLevel.LL_Notice:
        LogValue := '[Notice] ' + LogValue;
      TLogLevel.LL_Warning:
        LogValue := '[Warning] ' + LogValue;
      TLogLevel.LL_Error:
        LogValue := '[Error] ' + LogValue;
    end;

    ShowLog(LogValue, LogLevel);
    TmpValue := FormatDateTime(WRITE_LOG_FORMAT_DATE, Now);
    TmpValue := FLogName + TmpValue;
    ACompleteFileName := FLogDir + TmpValue + Suffix_name;

    TmpValue := FormatDateTime(WRITE_LOG_FORMAT_TIME, Now) + ':' + LogValue;
    if FileExists(ACompleteFileName) then
    begin
      OpenWriteTxt(ACompleteFileName, TmpValue);
    end
    else
    begin
      NewWriteTxt(ACompleteFileName, TmpValue);
    end;
  finally
    // LeaveCriticalSection(FCSLock);
  end;
end;

initialization
//   Log:=TXYSimpleLogger.Create('HttpApi',ExtractFilePath(ParamStr(0)) +'Log\');
finalization
  if Log <> nil then
    Log.Free;
end.
