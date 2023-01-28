unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameBlock,gameCell,
  enums,graphics,arrayUtils,clueCell;
type
  
  { TNonogramSolver }

  TNonogramSolver = class(TInterfacedObject)
    private
    fInitialState:TGameState;
    fSolvedGameState:TGameState;
    fChanges:TGameStateChanges;
    function overlapRow(rowId:integer):TGameStateChanges;
    function overlapColumn(columnId:integer):TGameStateChanges;
    function overlapRows:TGameStateChanges;
    function overlapColumns:TGameStateChanges;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    public
    constructor create(initialGameState:TGameState);
    function solve:TGameState; //should be some kind of result object
  end;

implementation

{ TNonogramSolver }

constructor TNonogramSolver.create(initialGameState:TGameState);
begin
  fInitialState:= initialGameState;
end;

{ Solve methods to be run repeatedly until there are no changes}
function TNonogramSolver.overlapRow(rowId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.overlapColumn(columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.overlapRows: TGameStateChanges;
var
  rowIndex:integer;
begin
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.overlapColumns: TGameStateChanges;
var
  colIndex:integer;
begin
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.processStepResult(stepResult:TGameStateChanges): integer;
var
  index:integer;
begin
  Result:=0;
  if stepResult.size = 0 then exit;
  for index:= 0 to pred(stepResult.size) do
    begin
      fChanges.push(stepResult[index]);
      result:=result+1;
    end;
end;

function TNonogramSolver.copyGameState(initialState: TGameState): TGameState;
var
  gameBlock:TGameBlock;
  gameCells:TGameCells;
  row,col:integer;
  cellId:TGUID;
  clueValue,clueIndex:integer;
  clueColour:TColor;
  blockIndex,cellIndex:integer;
  rowClueBlock,columnClueBlock:TClueBlock;
  clueCells:TClueCells;
begin
  //game cells
  gameBlock:=TGameBlock.Create;
  gameCells:=TGameCells.Create;
  for blockIndex:= 0 to pred(initialState.gameBlock.size) do
    begin
    setLength(gameCells,0);
    for cellIndex:=0 to Pred(initialState.gameBlock[blockIndex].size) do
      begin
      col:= initialState.gameBlock[blockIndex][cellIndex].col;
      row:= initialState.gameBlock[blockIndex][cellIndex].row;
      cellId:=initialState.gameBlock[blockIndex][cellIndex].cellId;
      gameCells.push(TGameCell.create(col,row,cellId));
      end;
    gameBlock.push(gameCells);
    end;
  //row clues
  rowClueBlock:=TClueBlock.Create;
  clueCells:=TClueCells.Create;
  for blockIndex:=0 to pred(initialState.rowClues.size) do
    begin
    setLength(clueCells,0);
    for cellIndex:=0 to pred(initialState.rowClues[blockIndex].size) do
      begin
      row:=initialState.rowClues[blockIndex][cellIndex].row;
      col:=initialState.rowClues[blockIndex][cellIndex].column;
      clueIndex:=initialState.rowClues[blockIndex][cellIndex].index;
      clueValue:=initialState.rowClues[blockIndex][cellIndex].value;
      clueColour:=initialState.rowClues[blockIndex][cellIndex].colour;
      clueCells.push(TClueCell.create(row,col,clueValue,clueIndex,clueColour));
      end;
    rowClueBlock.push(clueCells);
    end;
  //column clues
  columnClueBlock:=TClueBlock.Create;
  for blockIndex:=0 to pred(initialState.columnClues.size) do
    begin
    setLength(clueCells,0);
    for cellIndex:=0 to pred(initialState.columnClues[blockIndex].size) do
      begin
      row:=initialState.columnClues[blockIndex][cellIndex].row;
      col:=initialState.columnClues[blockIndex][cellIndex].column;
      clueIndex:=initialState.columnClues[blockIndex][cellIndex].index;
      clueValue:=initialState.columnClues[blockIndex][cellIndex].value;
      clueColour:=initialState.columnClues[blockIndex][cellIndex].colour;
      clueCells.push(TClueCell.create(row,col,clueValue,clueIndex,clueColour));
      end;
    columnClueBlock.push(clueCells);
    end;
end;


//Solve runner which calls each method in turn and deals with changes
function TNonogramSolver.solve: TGameState;
var
  changesOnCurrentLoop:integer;
begin
  //need to create a new gameState object with the initial settings
  fSolvedGameState:=copyGameState(fInitialState);
  changesOnCurrentLoop:=0;
    repeat
    changesOnCurrentLoop:=changesOnCurrentLoop + processStepResult(overlapRows);
    changesOnCurrentLoop:=changesOnCurrentLoop + processStepResult(overlapColumns);
    until changesOnCurrentLoop.size = 0;
  result:=fSolvedGameState;
end;

end.

