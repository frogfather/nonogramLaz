program nonotestproj;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, nonosolvertests, nonosolver, clueCell,
  gamestatechange, gameState, gameCell, gameSpace, clueOptionTest;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

