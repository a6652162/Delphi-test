unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext,
  IdCustomHTTPServer, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdHTTPServer, Vcl.StdCtrls, System.NetEncoding, Vcl.ExtCtrls, EncdDecd,
  IdMultipartFormData,Web.HTTPApp;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    Button1: TButton;
    Button2: TButton;
    Image1: TImage;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  uXYSimpleLogger, idMultipartFormDataReader;

{$R *.dfm}

{**************************************************************************
  名称：   BaseImage
  参数：   fn: TFilename
  返回值： string
  功能：   将fn文件转换成Base64编码，返回值为编码
 **************************************************************************}
function BaseImage(fn: string): string;
var
  m1: TMemoryStream;
  m2: TStringStream;
  str: string;
begin
  m1 := TMemoryStream.Create;
  m2 := TStringStream.Create;
  m1.LoadFromFile(fn);
  EncdDecd.EncodeStream(m1, m2);                       // 将m1的内容Base64到m2中
  str := m2.DataString;
  str := StringReplace(str, #13, '', [rfReplaceAll]);  // 这里m2中数据会自动添加回车换行，所以需要将回车换行替换成空字符
  str := StringReplace(str, #10, '', [rfReplaceAll]);
  result := str;                                       // 返回值为Base64的Stream
  m1.Free;
  m2.Free;
end;

function Base64Get(FileName: string): string;//读出文件内容为base64字符串   // 转码
var
  m: TMemoryStream;
  s: TStringStream;
begin
  result := '';
  if (FileExists(FileName)) then
  begin
    m := TMemoryStream.Create;
    s := TStringStream.Create;
    m.LoadFromFile(FileName);
//    encddecd.EncodeStream(m,s);
    TNetEncoding.Base64.Decode(m, s);
    result := s.DataString;
    FreeAndNil(m);
    FreeAndNil(s);
  end;
end;

procedure Base64Put(Base64Str, FileName: string);//base64字符串保存为文件  // 解码
var
  m: TMemoryStream;
  b: TBytes;
begin
  b := DecodeBase64(Base64Str);
  m := TMemoryStream.Create;
  m.Write(b, length(b));
  m.SaveToFile(FileName);
  FreeAndNil(m);
end;

function Base64Put1(Base64Str, FileName: String):Boolean;
  var
  aStream:TMemoryStream;
  vDataBytes:TBytes;
  iSize:Integer;
  Rest:Boolean;
  PB_Path:string;
begin
  Rest:=False;
  Try
    vDataBytes:=DecodeBase64(Base64Str);
    iSize := Length(vDataBytes);
    aStream:=TMemoryStream.Create;
    aStream.Position := 0;
    aStream.Write(vDataBytes[0],iSize);
    aStream.Position := 0;
    PB_Path := ExtractFilePath(FileName);
    if not DirectoryExists(PB_Path) then
    ForceDirectories(PB_Path);
    aStream.SaveToFile(FileName);
    FreeAndNil(aStream);
    //保存到附件数据库
    Rest:=True;
  except on E:exception do
    begin
//      HttpToFile('异常',E.Message);
      Rest:=False;
    end;
  End;
  Result:= Rest;
end;

function SplitString(const Source, Ch: string): TStringList;
var
    Temp: string;
    iLoop: Integer;
begin
  Result := TStringList.Create;
  Temp := Source;
  iLoop := Pos(Ch, Source);
  while iLoop <> 0 do
  begin
    Result.Add(copy(temp, 0, iLoop-1));
    Delete(temp, 1, iLoop);
    iLoop := Pos(Ch, Temp);
  end;
  Result.Add(temp);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  IdHTTPServer1.Active := not IdHTTPServer1.Active;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  LInputStream, LInputStream2: TFileStream;
  LOutputStream: TMemoryStream;
//  Png: TPNGImage;
  aBitmap: TBitmap;
begin
  LInputStream := TFileStream.Create('D:\011728.txt', fmOpenRead or fmShareDenyWrite);
  Base64Put(LInputStream.ToString, 'd:\test.png');
  exit;
  try
    LOutputStream := TMemoryStream.Create;
    try
      TNetEncoding.Base64.Decode(LInputStream, LOutputStream);
//      ShowMessage(LOutputStream.Size.ToString);
//      LOutputStream.SaveToFile('d:\test.png');
      LOutputStream.Position := 0;
//      Png := TPNGImage.Create;
      aBitmap := TBitmap.Create;
      try
        aBitmap.LoadFromStream(LOutputStream);
//        Png.LoadFromStream(LOutputStream);
        Image1.Picture.Assign(aBitmap);
      finally
        aBitmap.Free;
//        Png.Free;
      end;
    finally
      LOutputStream.Free;
    end;
  finally
    LInputStream.Free;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  tstr: Tstringlist;
begin
  tstr := Tstringlist.Create;
  tstr.Text := BaseImage('D:\011728.png');
  tstr.SaveToFile('D:\011728.txt');
  tstr.Free;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Base64Put(Base64Get('D:\011728.txt'), 'D:\011728New.png');
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  ss: string;
begin
  ss := BaseImage('D:\011728.png');
  Base64Put(ss, 'D:\011728New.png');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Log := TXYSimpleLogger.Create('test', ExtractFilePath(ParamStr(0)) + 'Log\');
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  FileStream: TFileStream;
  TmpPath, TmpValue, lFileName: string;
  strStream: TStringStream;
  Strl: TStringList;
  decoder: TIdMultiPartFormDataStreamReader;
  campo: TIdFormDataField;

  function GetFileName(lValue: string): string;
  var
    Strl1: TStringList;
  begin
    Strl1 := TStringList.Create;
    Strl1.Delimiter := ';';
    Strl1.DelimitedText := lValue;
    Result := Strl1.Strings[2];
    Result := Copy(lFileName, 11, Length(lFileName) - 1);
    Strl1.Free;
  end;


begin
  TmpValue := UTF8Decode(HttpDecode(ARequestInfo.FormParams));
  Log.WriteLog('ARequestInfo.Params:' + TmpValue);
  if TmpValue<>'' then
  begin
    Strl := SplitString(TmpValue,'&');
    try
      TmpValue :=Strl.Values['url'];
      Log.WriteLog('TmpValue:' + TmpValue);
      TmpValue := Copy(TmpValue,pos('base64,',TmpValue)+7,Length(TmpValue));
      Base64Put(TmpValue, 'D:\'+ Strl.Values['name']);
    finally
      if Strl <> nil then
        Strl.Free;
    end;
    Exit;
  end;
  if ARequestInfo.PostStream <> nil then
  begin
    TmpPath := ExtractFilePath(ParamStr(0)) + 'tem\';
    if not DirectoryExists(TmpPath) then
    begin
      ForceDirectories(TmpPath);
    end;
    strStream := TStringStream.Create('', TEncoding.UTF8);
    Strl := TStringList.Create;
    decoder := TIdMultiPartFormDataStreamReader.Create(ARequestInfo);
    try
      if decoder.Fields.Count>0 then
      begin
        campo := decoder.Fields.Items[0];
        Log.WriteLog(campo.ContentType);
        Log.WriteLog(campo.ContentTransfer);
        Log.WriteLog(campo.Charset);
        Log.WriteLog(campo.FileName);
        Log.WriteLog(campo.FieldName);
        if (campo.FileName <> '') then
        begin
          if (campo.FieldStream <> nil) then
          begin
            campo.FieldStream;
            FileStream := TFileStream.Create(TmpPath + campo.FileName, fmCreate);
            FileStream.CopyFrom(campo.FieldStream, campo.FieldStream.Size); { Copy 流 }
            FileStream.Free;
          end;
        end;
        Exit;
      end;

      ARequestInfo.PostStream.Position := 0;
      strStream.CopyFrom(ARequestInfo.PostStream,ARequestInfo.PostStream.Size);
      strStream.Position := 0;

      Strl.Text := strStream.DataString;
      TmpValue := Strl.Strings[1];
      lFileName := GetFileName(TmpValue);
      Strl.Delete(Strl.Count - 1);
      Strl.Delete(3);
      Strl.Delete(2);
      Strl.Delete(1);
      Strl.Delete(0);
      strStream.Clear;
      strStream.WriteString(Strl.Text);
      strStream.Position := 0;
      strStream.SaveToFile(TmpPath + '2.png');

//    FileStream := TFileStream.Create(TmpPath+ '1.png', fmCreate);
//    FileStream.CopyFrom(ARequestInfo.PostStream, ARequestInfo.PostStream.Size); { Copy 流 }
//    FileStream.Free;
    finally
      if strStream <> nil then
        strStream.Free;
      if Strl <> nil then
        Strl.Free;
      if FileStream <> nil then
        FileStream.Free;
      if decoder <> nil then
        decoder.Free;
    end;
  end;
  if True then

end;

end.

