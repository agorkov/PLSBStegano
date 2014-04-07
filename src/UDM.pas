unit UDM;

interface

uses
  SysUtils, Classes, Dialogs, ExtDlgs;

type
  TDMMain = class(TDataModule)
    OPD: TOpenPictureDialog;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DMMain: TDMMain;

implementation

{$R *.dfm}

end.
