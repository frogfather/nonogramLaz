program nonotestproj;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, nonosolvertests, nonosolver, clueCell;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

