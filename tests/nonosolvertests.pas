unit nonosolvertests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,nonosolver,clueCell,
  graphics,gameState,gameStateChanges,gameCell,gamegrid,enums,gameSpace;

type
  
  { TNgTestSolver }

  TNgTestSolver = class(TNonogramSolver)
    public
    function overlapRowMethod(gameState:TGameState;rowId:integer):TGameStateChanges;
    function overlapColumnMethod(gameState:TGameState;columnId:integer):TGameStateChanges;
    function setClueCandidatesMethod(var spaces: TGameSpaces;clues: TClueCells):TGameSpaces;
    function edgeProximityRowMethod(gameState: TGameState; rowId: integer):TGameStateChanges;
    function identifyCluesRowMethod(gameState: TGameState; rowId: integer):TGameStateChanges;
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
    procedure overlapTwoCluesSameColourFilledCellMatchesFirstClue;
    procedure nonOverlapTwoCluesDifferentColour;
    procedure overlapTwoCluesDifferentColourFilledCellMatchesSecondClue;
    procedure overlapTwoCluesDifferentColourFilledCellMatchesFirstClue;
    procedure overlapTwoSpaces;
    procedure overlapTwoSpacesMultipleClues;
    procedure setCandidatesThreeSpaces;
    procedure setCandidatesThreeSpacesDifferentColours;
    procedure edgeProximityRowLeftNoAction;
    procedure edgeProximityRowLeftFillOne;
    procedure edgeProximityRowLeftCrossTwo;
    procedure edgeProximityRowLeftFilledCellsMatchFirstClue;
    //procedure identifyCluesRowNoResults;
    //procedure identifyCluesRowThreeOverlap;
    //procedure identifyCluesRowTwoClues;
    //procedure identifyCluesRowTwoCluesTwoColours;
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
  result:= ngTestSolver.setClueCandidates(spaces,clues);
end;

function TNgTestSolver.edgeProximityRowMethod(gameState: TGameState;
  rowId: integer): TGameStateChanges;
begin
  result:=ngTestSolver.edgeProximityRow(gameState,rowId);
end;

function TNgTestSolver.identifyCluesRowMethod(gameState: TGameState;
  rowId: integer): TGameStateChanges;
begin
  result:=ngTestSolver.identifyCluesRow(gameState,rowId);
end;

{ TNgTestSolver }



procedure TNonoSolverTests.SetUp;
var
  gameBlock:TGameGrid;
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
  gameBlock:=TGameGrid.create;
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
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0));
  AssertEquals(1,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoCluesSameColourFilledCellMatchesFirstClue;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0));
  gameState_.gameGrid[0][2].fill:=cfFill;
  AssertEquals(2,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.nonOverlapTwoCluesDifferentColour;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0,clBlue));
  AssertEquals(0,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoCluesDifferentColourFilledCellMatchesSecondClue;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0,clBlue));
  gameState_.gameGrid[0][2].fill:=cfFill;
  AssertEquals(0,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoCluesDifferentColourFilledCellMatchesFirstClue;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,9,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0,clBlue));
  gameState_.gameGrid[0][2].fill:=cfFill;
  gameState_.gameGrid[0][2].colour:=clBlue;
  AssertEquals(1,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.overlapTwoSpaces;
begin
  //clue 1 (first clue) can go in either space so no action
  //clue 0 (second clue) can only go in second space
  gameState_.rowClues[0].push(TClueCell.create(0,-1,13,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,0));
  gameState_.gameGrid[0][3].fill:=cfCross;
  AssertEquals(10,ngTestSolver.overlapRowMethod(gameState_,0).size);

end;

procedure TNonoSolverTests.overlapTwoSpacesMultipleClues;
begin
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,3));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,1,2));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,2,1));
  gameState_.rowClues[0].push(TClueCell.create(0,-1,3,0));
  gameState_.gameGrid[0][7].fill:=cfCross;
  gameState_.gameGrid[0][8].fill:=cfCross;
  gameState_.gameGrid[0][15].fill:=cfCross;
  gameState_.gameGrid[0][16].fill:=cfCross;
  gameState_.gameGrid[0][17].fill:=cfCross;
  gameState_.gameGrid[0][18].fill:=cfCross;
  gameState_.gameGrid[0][19].fill:=cfCross;
  AssertEquals(3,ngTestSolver.overlapRowMethod(gameState_,0).size);
end;

procedure TNonoSolverTests.setCandidatesThreeSpaces;
var
  testSpaces:TGameSpaces;
  testClues:TClueCells;
begin
  testCLues:=TClueCells.create;
  testClues.push(TClueCell.create(0,-1,2,0));
  testClues.push(TClueCell.create(0,-1,4,1));
  testClues.push(TClueCell.create(0,-1,1,2));
  testSpaces:=TGameSpaces.create;
  testSpaces.push(TGameSpace.create(0,7));
  testSpaces.push(TGameSpace.create(9,11));
  AssertEquals(2,ngTestSolver.setClueCandidatesMethod(testSpaces,testClues)[0].candidates.size);
end;

procedure TNonoSolverTests.setCandidatesThreeSpacesDifferentColours;
var
  testSpaces:TGameSpaces;
  testClues:TClueCells;
begin
  testCLues:=TClueCells.create;
  testClues.push(TClueCell.create(0,-1,2,0));
  testClues.push(TClueCell.create(0,-1,4,1,clRed));
  testClues.push(TClueCell.create(0,-1,1,2));
  testSpaces:=TGameSpaces.create;
  testSpaces.push(TGameSpace.create(0,7));
  testSpaces.push(TGameSpace.create(9,11));
  AssertEquals(3,ngTestSolver.setClueCandidatesMethod(testSpaces,testClues)[0].candidates.size);
end;

//If there is enough space between the left side of the grid and the
//first filled cell then we cannot make any deductions about what cells
//should be filled.
procedure TNonoSolverTests.edgeProximityRowLeftNoAction;
var
  changes:TGameStateChanges;
begin
  gameState_.gameGrid[0][4].fill:=cfFill;
  gameState_.rowClues[0].push(TClueCell.create(0,-1,3,0));
  changes:= ngTestSolver.edgeProximityRowMethod(gameState_,0);
  assertEquals(0,changes.size);
end;

//If the first cell is as far left as possible
//it would cover an unfilled cell - this should
//have been caught by previous methods
procedure TNonoSolverTests.edgeProximityRowLeftFillOne;
var
  changes:TGameStateChanges;
begin
  gameState_.gameGrid[0][4].fill:=cfFill;
  gameState_.rowClues[0].push(TClueCell.create(0,-1,6,0));
  changes:= ngTestSolver.edgeProximityRowMethod(gameState_,0);
  assertEquals(1,changes.size);
  AssertEquals(5,changes[0].column);
end;

//The position of the filled cells means that cells 0 and 1 cannot
//be filled so we mark them with crosses
procedure TNonoSolverTests.edgeProximityRowLeftCrossTwo;
var
  changes:TGameStateChanges;
begin
  gameState_.gameGrid[0][4].fill:=cfFill;
  gameState_.gameGrid[0][5].fill:=cfFill;
  gameState_.gameGrid[0][6].fill:=cfFill;
  gameState_.rowClues[0].push(TClueCell.create(0,-1,5,0));
  changes:= ngTestSolver.edgeProximityRowMethod(gameState_,0);
  assertEquals(2,changes.size);
  AssertEquals(0,changes[0].column);
  AssertEquals(1,changes[1].column);
  Assert(changes[0].cellFillMode = cfCross);
  Assert(changes[1].cellFillMode = cfCross);
end;

//The length of the filled cells exactly matches the size of the first clue
//so all the cells before the first filled cell should be marked with crosses
procedure TNonoSolverTests.edgeProximityRowLeftFilledCellsMatchFirstClue;
var
  changes:TGameStateChanges;
begin
  gameState_.gameGrid[0][4].fill:=cfFill;
  gameState_.gameGrid[0][5].fill:=cfFill;
  gameState_.gameGrid[0][6].fill:=cfFill;
  gameState_.gameGrid[0][7].fill:=cfFill;
  gameState_.gameGrid[0][8].fill:=cfFill;
  gameState_.rowClues[0].push(TClueCell.create(0,-1,5,0));
  changes:= ngTestSolver.edgeProximityRowMethod(gameState_,0);
  assertEquals(4,changes.size);
end;

//procedure TNonoSolverTests.identifyCluesRowNoResults;
//var
//  changes:TGameStateChanges;
//begin
//  //short clues - no cells are identified
//  gameState_.gameGrid[0][4].fill:=cfFill;
//  gameState_.gameGrid[0][5].fill:=cfFill;
//  gameState_.gameGrid[0][6].fill:=cfFill;
//  gameState_.gameGrid[0][7].fill:=cfFill;
//  gameState_.gameGrid[0][8].fill:=cfFill;
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,5,0));
//  changes:=ngTestSolver.identifyCluesRowMethod(gameState_,0);
//  assertEquals(0, changes.size);
//end;
//
//procedure TNonoSolverTests.identifyCluesRowThreeOverlap;
//var
//  changes:TGameStateChanges;
//begin
//  gameState_.gameGrid[0][4].fill:=cfFill;
//  gameState_.gameGrid[0][5].fill:=cfFill;
//  gameState_.gameGrid[0][6].fill:=cfFill;
//  gameState_.gameGrid[0][7].fill:=cfFill;
//  gameState_.gameGrid[0][8].fill:=cfFill;
//  gameState_.gameGrid[0][9].fill:=cfCross;
//  gameState_.gameGrid[0][14].fill:=cfCross;
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,6,0));
//  changes:=ngTestSolver.identifyCluesRowMethod(gameState_,0);
//  assertEquals(3, changes.size);
//end;
//
//procedure TNonoSolverTests.identifyCluesRowTwoClues;
//var
//  changes:TGameStateChanges;
//begin
//  gameState_.gameGrid[0][12].fill:=cfCross;
//  gameState_.gameGrid[0][14].fill:=cfCross;
//  gameState_.gameGrid[0][16].fill:=cfCross;
//  gameState_.gameGrid[0][18].fill:=cfCross;
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,3,0));
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,5,1));
//  changes:=ngTestSolver.identifyCluesRowMethod(gameState_,0);
//  assertEquals(2, changes.size);
//end;
//
//procedure TNonoSolverTests.identifyCluesRowTwoCluesTwoColours;
//var
//  changes:TGameStateChanges;
//begin
//  gameState_.gameGrid[0][12].fill:=cfCross;
//  gameState_.gameGrid[0][14].fill:=cfCross;
//  gameState_.gameGrid[0][16].fill:=cfCross;
//  gameState_.gameGrid[0][18].fill:=cfCross;
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,3,0,clRed));
//  gameState_.rowClues[0].push(TClueCell.create(0,-1,5,1));
//  changes:=ngTestSolver.identifyCluesRowMethod(gameState_,0);
//  assertEquals(1, changes.size);
//  assertEquals(clBlack,changes[0].colour);
//end;



initialization

  RegisterTest(TNonoSolverTests);
end.

