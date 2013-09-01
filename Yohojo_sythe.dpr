program Yohojo_sythe;

uses
  Forms,
  main in 'main.pas' {Form1},
  sythe_utils in 'sythe_utils.pas',
  ThreadParser in 'ThreadParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
