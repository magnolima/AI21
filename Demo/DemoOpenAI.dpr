program DemoOpenAI;

uses
  System.StartUpCopy,
  FMX.Forms,
  uDemoAI21 in 'uDemoAI21.pas' {frmDemoOpenAI},
  MLAI21.Complete in '..\Lib\MLAI21.Complete.pas',
  MLAI21.Core in '..\Lib\MLAI21.Core.pas',
  MLAI21.Types in '..\Lib\MLAI21.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmDemoOpenAI, frmDemoOpenAI);
  Application.Run;
end.
