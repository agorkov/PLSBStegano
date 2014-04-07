program PLSBStegano;

uses
  Forms,
  UFMain in 'UFMain.pas' {FMain},
  UDM in 'UDM.pas' {DMMain: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  //Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDMMain, DMMain);
  Application.Run;
end.
