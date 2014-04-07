unit UFMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TFMain = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    BSelectImage: TButton;
    MMsg: TMemo;
    BWriteData: TButton;
    BReadData: TButton;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    CheckBox1: TCheckBox;
    procedure FormActivate(Sender: TObject);
    procedure BWriteDataClick(Sender: TObject);
    procedure BReadDataClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure MMsgChange(Sender: TObject);
    procedure BSelectImageClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FMain: TFMain;

implementation
{$R *.dfm}
uses
  UDM;

type
  TRBMPInfo = record
    FileName: string;
    bfSize, bfOffbits, MaxMsgSize: LongWord;
    bfReserved1, bfReserved2: word;
  end;

var
BMPInfo: TRBMPInfo;

///
///  Очистка картинки
///
procedure ClearImage;
begin
  FMain.Image1.Canvas.Rectangle(0,0,FMain.Image1.Width,FMain.Image1.Height);
end;

///
///  Получение информации о bmp-файле
///
procedure GetFileInfo;
var
f: TFileStream;
bfType: word;
begin
  f:=TFileStream.Create(BMPInfo.FileName,fmOpenRead);
  f.Read(bfType,sizeof(bfType));
  f.Read(BMPInfo.bfSize,sizeof(BMPInfo.bfSize));
  f.Read(BMPInfo.bfReserved1,sizeof(BMPInfo.bfReserved1));
  f.Read(BMPInfo.bfReserved2,sizeof(BMPInfo.bfReserved2));
  f.Read(BMPInfo.bfOffbits,sizeof(BMPInfo.bfOffbits));
  BMPInfo.MaxMsgSize:=(BMPInfo.bfSize-BMPInfo.bfOffbits) div 2;
  f.Free;
end;

///
///  Выбор и загрузка изображения
///
function SelectImage: boolean;
var
res: boolean;
begin
  res:=false;
  if UDM.DMMain.OPD.Execute then
  begin
    FMain.Image1.Picture.LoadFromFile(UDM.DMMain.OPD.FileName);
    BMPInfo.FileName:=UDM.DMMain.OPD.FileName;
    GetFileInfo;
    FMain.Label1.Caption:='Макс. - '+inttostr(BMPInfo.MaxMsgSize)+' байт';
    res:=true;
  end
  else
  begin
    ClearImage;
    FMain.Label1.Caption:='';
    res:=false;
  end;
  Result:=res;
end;

///
///  Выбор изображения
///
procedure TFMain.BSelectImageClick(Sender: TObject);
begin
  SelectImage;
end;

///
///  Запись данных в картинку
///
procedure TFMain.BWriteDataClick(Sender: TObject);
var
f: TFileStream;
MsgSize: LongWord;
mode: byte;
i: LongWord;
l1,l2,l3,l4,l5,l6,l7,l8,tmp: byte;
str: string;
begin
  ///
  ///  Проверка наличия картинки
  ///
  if BMPInfo.FileName='' then
  begin
    if not SelectImage then
      Exit;
  end;

  ///
  ///  Проверка ёмкости картинки
  ///
  if length(MMsg.Text)<(BMPInfo.MaxMsgSize div 8) then
    mode:=1
  else
    if length(MMsg.Text)<(BMPInfo.MaxMsgSize div 4) then
      mode:=2
    else
      if length(MMsg.Text)<(BMPInfo.MaxMsgSize) then
        mode:=4
      else
      begin
        ShowMessage('Сообщение слишком большое');
        Exit;
      end;
  if length(MMsg.Text)>=1073741824 then
  begin
    ShowMessage('Сообщение слишком большое');
    Exit;
  end;

  ///
  ///  Подготовка интерфейса
  ///
  ProgressBar1.Max:=length(MMsg.Text);
  ProgressBar1.Position:=0;

  ///
  ///  Запись размера сообщения
  ///  и типа кодирования
  ///
  f:=TFileStream.Create(BMPInfo.FileName,fmOpenReadWrite);
  f.Seek(6,soFromBeginning);
  MsgSize:=length(MMsg.Text);
  msgSize:=MsgSize shl 2;
  case mode of
  1: MsgSize:=MsgSize+1;
  2: MsgSize:=MsgSize+2;
  4: MsgSize:=MsgSize+3;
  end;{case}
  f.WriteBuffer(MsgSize,sizeof(MsgSize));
  f.Seek(BMPInfo.bfOffbits,soFromBeginning);

  ///
  ///  Запись информации
  ///
  str:=MMsg.Text;
  if mode=4 then
  begin
    for i:=1 to length(str) do
    begin
      l1:=byte(str[i]) shr 4;
      l2:=(byte(str[i]) shl 4); l2:=l2 shr 4;

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 4) shl 4)+l1;
      f.WriteBuffer(tmp,1);
      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 4) shl 4)+l2;
      f.WriteBuffer(tmp,1);

      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  if mode=2 then
  begin
    for i:=1 to length(str) do
    begin
      l1:=byte(str[i]) shr 6;
      l2:=byte(str[i]) shl 2; l2:=l2 shr 6;
      l3:=byte(str[i]) shl 4; l3:=l3 shr 6;
      l4:=byte(str[i]) shl 6; l4:=l4 shr 6;

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 2) shl 2)+l1;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 2) shl 2)+l2;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 2) shl 2)+l3;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 2) shl 2)+l4;
      f.WriteBuffer(tmp,1);

      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  if mode=1 then
  begin
    for i:=1 to length(str) do
    begin
      l1:=byte(str[i]) shr 7;
      l2:=byte(str[i]) shl 1; l2:=l2 shr 7;
      l3:=byte(str[i]) shl 2; l3:=l3 shr 7;
      l4:=byte(str[i]) shl 3; l4:=l4 shr 7;
      l5:=byte(str[i]) shl 4; l5:=l5 shr 7;
      l6:=byte(str[i]) shl 5; l6:=l6 shr 7;
      l7:=byte(str[i]) shl 6; l7:=l7 shr 7;
      l8:=byte(str[i]) shl 7; l8:=l8 shr 7;

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l1;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l2;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l3;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l4;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l5;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l6;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l7;
      f.WriteBuffer(tmp,1);

      f.ReadBuffer(tmp,1);
      f.Position:=f.Position-1;
      tmp:=((tmp shr 1) shl 1)+l8;
      f.WriteBuffer(tmp,1);
      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  ///
  ///  Зашумление оставшейся части изображения
  ///
  if CheckBox1.Checked then
  begin
    ProgressBar1.Max:=f.Size-f.Position;
    ProgressBar1.Position:=0;
    for i:=f.Position to BMPInfo.bfSize-1 do
    begin
      case mode of
      1:
      begin
        f.ReadBuffer(l1,1);
        f.Position:=f.Position-1;
        tmp:=random(256);
        l1:=l1 shr 1; l1:=l1 shl 1;
        tmp:=tmp shl 7; tmp:=tmp shr 7;
        l1:=l1+tmp;
        f.WriteBuffer(l1,1);
      end;
      2:
      begin
        f.ReadBuffer(l1,1);
        f.Position:=f.Position-1;
        tmp:=random(256);
        l1:=l1 shr 2; l1:=l1 shl 2;
        tmp:=tmp shl 6; tmp:=tmp shr 6;
        l1:=l1+tmp;
        f.WriteBuffer(l1,1);
      end;
      4:
      begin
        f.ReadBuffer(l1,1);
        f.Position:=f.Position-1;
        tmp:=random(256);
        l1:=l1 shr 4; l1:=l1 shl 4;
        tmp:=tmp shl 4; tmp:=tmp shr 4;
        l1:=l1+tmp;
        f.WriteBuffer(l1,1);
      end;
      end;{case}
      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  ///
  ///  Вывод результатов
  ///  и освобождение ресурсов
  ///
  case mode of
  1: ShowMessage('Запись выполнена. Минимальные искажения');
  2: ShowMessage('Запись выполнена. Средние искажения');
  4: ShowMessage('Запись выполнена. Максимальные искажения');
  end;{case}
  ProgressBar1.Position:=0;
  f.Free;
end;

///
///  Считывание данных из картинки
///
procedure TFMain.BReadDataClick(Sender: TObject);
var
f: TFileStream;
MsgSize: LongWord;
mode: byte;
i: LongWord;
l1,l2,l3,l4,l5,l6,l7,l8,tmp: byte;
str: string;
begin
  ///
  ///  Проверка наличия картинки
  ///
  if BMPInfo.FileName='' then
  begin
    if not SelectImage then
      Exit;
  end;

  ///
  ///  Подготовка интерфейса
  ///
  MMsg.Lines.Clear;
  ProgressBar1.Max:=MsgSize;
  ProgressBar1.Position:=0;
  str:='';

  ///
  ///  Считывание размера сообщения
  ///  и типа кодирования
  ///
  f:=TFileStream.Create(BMPInfo.FileName,fmOpenReadWrite);
  f.Seek(6,soFromBeginning);
  f.ReadBuffer(MsgSize,sizeof(MsgSize));
  mode:=(MsgSize shl 30) shr 30;
  case mode of
  1: mode:=1;
  2: mode:=2;
  3: mode:=4;
  end;{case}
  MsgSize:=MsgSize shr 2;

  ///
  ///  Чтение информации
  ///
  f.Seek(BMPInfo.bfOffbits,soFromBeginning);
  if mode=4 then
  begin
    for i:=1 to MsgSize do
    begin
      f.ReadBuffer(tmp,1);
      l1:=tmp shl 4;
      f.ReadBuffer(tmp,1);
      l2:=tmp shl 4; l2:=l2 shr 4;
      str:=str+char(l1+l2);
      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  if mode=2 then
  begin
    for i:=1 to MsgSize do
    begin
      f.ReadBuffer(tmp,1);
      l1:=tmp shl 6;
      f.ReadBuffer(tmp,1);
      l2:=tmp shl 6; l2:=l2 shr 2;
      f.ReadBuffer(tmp,1);
      l3:=tmp shl 6; l3:=l3 shr 4;
      f.ReadBuffer(tmp,1);
      l4:=tmp shl 6; l4:=l4 shr 6;
      str:=str+char(l1+l2+l3+l4);
      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  if mode=1 then
  begin
    for i:=1 to MsgSize do
    begin
      f.ReadBuffer(tmp,1);
      l1:=tmp shl 7;
      f.ReadBuffer(tmp,1);
      l2:=tmp shl 7; l2:=l2 shr 1;
      f.ReadBuffer(tmp,1);
      l3:=tmp shl 7; l3:=l3 shr 2;
      f.ReadBuffer(tmp,1);
      l4:=tmp shl 7; l4:=l4 shr 3;
      f.ReadBuffer(tmp,1);
      l5:=tmp shl 7; l5:=l5 shr 4;
      f.ReadBuffer(tmp,1);
      l6:=tmp shl 7; l6:=l6 shr 5;
      f.ReadBuffer(tmp,1);
      l7:=tmp shl 7; l7:=l7 shr 6;
      f.ReadBuffer(tmp,1);
      l8:=tmp shl 7; l8:=l8 shr 7;
      str:=str+char(l1+l2+l3+l4+l5+l6+l7+l8);
      ProgressBar1.Position:=ProgressBar1.Position+1;
    end;
  end;

  ///
  ///  Вывод результатов
  ///  и освобождение ресурсов
  ///
  MMsg.Text:=str;
  ProgressBar1.Position:=0;
  f.Free;
end;

///
///  Очистка картинки при старте приложения
///
procedure TFMain.FormActivate(Sender: TObject);
begin
  ClearImage;
end;

///
///  Запрещаем изменение размеров формы
///
procedure TFMain.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  Resize:=false;
end;

///
///  Выводим размер сообщения
///
procedure TFMain.MMsgChange(Sender: TObject);
begin
  Label2.Caption:=inttostr(length(MMsg.Text))+' байт';
end;

end.
