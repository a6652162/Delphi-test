{
  普通版日志
}
unit uXYSimpleLogger;

interface

uses Windows, Classes, SysUtils, StdCtrls, Messages, System.StrUtils,
  System.Contnrs,cxMemo;

const
  WRITE_LOG_FLAG = 'xylog\'; // 记录日志默认目录
  WRITE_LOG_FORMAT_DATE = 'yyyy-mm-dd'; // 日期
  WRITE_LOG_FORMAT_TIME = 'hh:nn:ss.zzz'; // 时间
  SHOW_LOG_ADD_TIME = True; // 日志显示容器是否添加时间
  SHOW_LOG_TIME_FORMAT = 'yyyy/mm/dd hh:nn:ss.zzz'; // 日志显示添加时间的格式
  SHOW_LOG_CLEAR_COUNT = 1000; // 日志显示容器最大显示条数
  Suffix_name = '.txt'; //后缀名称


type
  TLogLevel = (LL_Info,LL_Notice,LL_Warning,LL_Error);
type
  TXYSimpleLogger = class
  private
    FCSLock: TRTLCriticalSection; // 临界区
    // FFileStream: TFileStream; //文件流
    FLogShower: TComponent; // 日志显示容器
    FLogDir: AnsiString; // 日志目录
    FLogName: AnsiString; // 日志名称
    FLogFlag: AnsiString; // 日志标识
    FLogFileCout: Integer; //保存天数
  protected
    procedure ShowLog(Log: AnsiString; const LogLevel: TLogLevel = LL_Info);
    procedure NewWriteTxt(filename: string; str: string);
    procedure OpenWriteTxt(filename: string; str: string);
    { *******根据扩展名遍历文件夹下的文件************* }
    procedure EnumFileInQueue(path: PAnsiChar; fileExt: string; fileList: TStringList);
    procedure log_del;// 删除过期的日志文件
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
//      raise Exception.Create('日志路径错误，日志类对象不能被创建');
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
      raise Exception.Create('日志路径错误，日志类对象不能被创建');
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
  dirs := TQueue.Create; // 创建目录队列
  dirs.Push(path); // 将起始搜索路径入队
  pszDir := dirs.Pop;
  curDir := StrPas(pszDir); // 出队
  { 开始遍历,直至队列为空(即没有目录需要遍历) }
  while (True) do
  begin
    // 加上搜索后缀,得到类似'c:\*.*' 、'c:\windows\*.*'的搜索路径
    tmpStr := curDir + '\*.*';
    // 在当前目录查找第一个文件、子目录
    found := FindFirst(tmpStr, faAnyFile, searchRec);
    while found = 0 do // 找到了一个文件或目录后
    begin
      // 如果找到的是个目录
      if (searchRec.Attr and faDirectory) <> 0 then
      begin
        { 在搜索非根目录(C:\、D:\)下的子目录时会出现'.','..'的"虚拟目录"
          大概是表示上层目录和下层目录吧。。。要过滤掉才可以 }
        if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
        begin
          { 由于查找到的子目录只有个目录名，所以要添上上层目录的路径
            searchRec.Name = 'Windows';
            tmpStr:='c:\Windows';
            加个断点就一清二楚了
          }
          tmpStr := curDir + '\' + searchRec.Name;
          { 将搜索到的目录入队。让它先晾着。
            因为TQueue里面的数据只能是指针,所以要把string转换为PChar
            同时使用StrNew函数重新申请一个空间存入数据，否则会使已经进
            入队列的指针指向不存在或不正确的数据(tmpStr是局部变量)。 }
          dirs.Push(StrNew(PChar(tmpStr)));
        end;
      end
      else // 如果找到的是个文件
      begin
        { Result记录着搜索到的文件数。可是我是用CreateThread创建线程
          来调用函数的，不知道怎么得到这个返回值。。。我不想用全局变量 }
        // 把找到的文件加到Memo控件
        if fileExt = '.*' then
          fileList.Add(curDir + '\' + searchRec.Name)
        else
        begin
          if SameText(RightStr(curDir + '\' + searchRec.Name, Length(fileExt)),
            fileExt) then
            fileList.Add(curDir + '\' + searchRec.Name);
        end;
      end;
      // 查找下一个文件或目录
      found := FindNext(searchRec);
    end;
    { 当前目录找到后，如果队列中没有数据，则表示全部找到了；
      否则就是还有子目录未查找，取一个出来继续查找。 }
    if dirs.Count > 0 then
    begin
      pszDir := dirs.Pop;
      curDir := StrPas(pszDir);
      StrDispose(pszDir);
    end
    else
      break;
  end;
  // 释放资源
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
    // 滚屏到最后一行
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
    // 滚屏到最后一行
    SendMessage(TcxMemo(FLogShower).Handle, WM_VSCROLL, SB_LINEDOWN, 0);
    if lineCount >= SHOW_LOG_CLEAR_COUNT then
      TcxMemo(FLogShower).Clear;
  end
  else
    raise Exception.Create('日志容器类型不支持:' + FLogShower.ClassName);
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
