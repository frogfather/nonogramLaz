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
  Forms, nonoForm, nonogramGame, gameCell, gameDisplay, arrayUtils, anysort,
  clickDelegate, clueCell, updateDelegate, gamegrid, gameState,
  gamestatechange, enums, gameStateChanges, drawingUtils, nonosolver,
  xml_doc_handler, nonodochandler, gamemodechangeddelegate, cluechangeddelegate,
  clueclickeddelegate, newgamedialog, fileUtilities, iNonoSolver, gameSpace,
  spaceclueblock;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfNonogram, fNonogram);
  Application.CreateForm(TfNewGameDialog, fNewGameDialog);
  Application.Run;
end.

