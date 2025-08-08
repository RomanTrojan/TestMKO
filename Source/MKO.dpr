program MKO;

uses
  Vcl.Forms,
  unMain in 'unMain.pas' {mtMain},
  MKO.Features in 'MKO.Features.pas',
  frFeature in 'frFeature.pas' {frFeatureProperty: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TmtMain, mtMain);
  Application.Run;
end.
