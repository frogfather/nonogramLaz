unit nonosolvertests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,nonosolver,clueCell,
  graphics,gameState,gameStateChanges,gameCell,gameBlock,enums,gameSpace;

type
  
  { TNgTestSolver }

  TNgTestSolver = class(TNonogramSolver)
    public
    function overlapRowMethod(gameState:TGameState;rowId:integer):TGameStateChanges;
    function overlapColumnMethod(gameState:TGameState;columnId:integer):TGameStateChanges;
    function setClueCandidatesMethod(var spaces: TGameSpaces;clues: TClueCells):TGameSpaces;
  end;

  { TNonoSolverTests }

  TNonoSolverTests= class(TTestCase)
  private
    fGameState:TGameState;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure overlapSingleClue;
    procedure overlapTwoCluesSameColour;
    procedure nonOverlapTwoCluesDifferentColour;
    procedure overlapTwoSpaces;
    procedure setCandidatesThreeSpaces;
    property gameState_: TGameState read fGameState write fGameState;
  end;

var
  ngTestSolver:TNgTestSolver;
  colour1:TColor;
  colour2:TColor;

implementation

{ TNgTestSolver }

function TNgTestSolver.overlapRowMethod(gameState: TGameState; rowId: integer
  ): TGameStateChanges;
begin
  result:=ngTestSolver.overlapRow(gameState,rowId);
end;

function TNgTestSolver.overlapColumnMethod(gameState: TGameState; columnId: integer
  ): TGameStateChanges;
begin
  result:=ngTestSolver.overlapColumn(gameState,columnId);
end;

function TNgTestSolver.setClueCandidatesMethod(var spaces: TGameSpaces;
  clues: TClueCells):TGameSpaces;
begin
  ngTestSolver.setClueCandidatesMethod(spaces,clues);
  result:=spaces;
end;

{ TNgTestSolver }



procedure TNonoSolverTests.SetUp;
var
  gameBlock:TGameBlock;
  gameCells:TGameCells;
  rowClueBlock,colClueBlock:TClueBlock;
  rowClueCells,colClueCells:TClueCells;
  rowId,colId:integer;
  dummyGuid:TGUID;
begin
  colour1:=$00FF00;
  colour2:=$FF0000;
  ngTestSolver:=TNgTestSolver.create;

  //Game cells
  gameBlock:=TGameBlock.create;
  createGuid(dummyGuid);
  for rowId:=0 to 19 do
    begin
    gameCells:=TGameCells.create;
    for colId:= 0 to 19 do
      gameCells.push(TGameCell.create(colId,rowId,dummyGuid,clBlack,cfEmpty));
    gameBlock.push(gameCells);
    end;

  //Row Clue Block - one row only for testing
  rowClueBlock:=TClueBlock.create;
  rowClueCells:=TClueCells.create;
  rowClueBlock.push(rowClueCells);

  colClueBlock:=TClueBlock.create;
  colClueCells:=TClueCells.create;
  colClueBlock.push(colClueCells);

  gameState_:=TGameState.create(gameBlock,rowClueBlock,colClueBlock);
end;

procedure TNonoSolverTests.TearDown;
begin

end;

procedure TNonoSolverTests.overlapSingleClue;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,11,0));
  AssertEquals(2,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoCluesSameColour;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  AssertEquals(1,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.nonOverlapTwoCluesDifferentColour;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0,clBlue));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  AssertEquals(0,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoSpaces;
begin
  //If there are two distinct spaces in a row then it should
  //work out that the first clue can only go in the first space
  //and the second can only go in the second
  //The first clue overlaps a single cell in the first space
  //and the second overlaps 10 cells in the second space
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,13,1));
  gameState_.gameBlock[0][3].fill:=cfCross;
  AssertEquals(11,ngTestSolver.overlapRowMethod(gameState_,0).size);

end;

procedure TNonoSolverTests.setCandidatesThreeSpaces;
var
  testSpaces:TGameSpaces;
  testClues:TClueCells;
begin
  testSpaces:=TGameSpaces.create;
  testSpaces.push(TClueCell.create(0,-1,2,0);
end;



initialization

  RegisterTest(TNonoSolverTests);
end.

