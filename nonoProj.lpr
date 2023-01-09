program nonoProj;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, nonoForm, nonogramGame, gameCell, gameDisplay, gameDisplayInterface,
  arrayUtils, anysort, clickDelegate, clueCell, updateDelegate, gameBlock, 
gameState, gamestatechange, enums, gameStateChanges
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfNonogram, fNonogram);
  Application.Run;
end.

