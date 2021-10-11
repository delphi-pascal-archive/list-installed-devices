program DevList;

uses
  Forms,
  uMain in 'Source\uMain.pas' {dlgMain},
  SetupApi in 'Source\SetupApi.pas',
  ModuleLoader in 'Source\ModuleLoader.pas',
  DeviceHelper in 'Source\DeviceHelper.pas',
  Common in 'Source\Common.pas',
  ListViewHelper in 'Source\ListViewHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdlgMain, dlgMain);
  Application.Run;
end.
