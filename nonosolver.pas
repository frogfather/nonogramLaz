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
    function overlapRows:integer;
    function overlapColumns:integer;
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
var
  clues:TClueCells;
begin
  clues:=fSolvedGameState.rowClues[rowId];
  result:=TGameStateChanges.create;
  //process this row to look for overlaps

end;

function TNonogramSolver.overlapColumn(columnId: integer): TGameStateChanges;
var
  cells:TGameCells;
  clues:TClueCells;
  rowIndex:integer;
begin
  cells:=TGameCells.create;
  //get the cells in a format we can process more easily
  for rowIndex:= 0 to pred(fSolvedGameState.gameBlock.size) do
    cells.push(fSolvedGameState.gameBlock[rowIndex][columnId]);
  //get the clues for this column
  clues:=fSolvedGameState.columnClues[columnId];
  result:=TGameStateChanges.create;
  //process this column to look for overlaps

end;

function TNonogramSolver.overlapRows: integer;
var
  rowIndex:integer;
  clues:TClueCells;
begin
  result:=0;
  //each row of the game block is a row of the puzzle
  for rowIndex:=0 to pred(fSolvedGameState.gameBlock.size) do
    result:= result + processStepResult(overlapRow(rowIndex));
end;

function TNonogramSolver.overlapColumns: integer;
var
  colIndex:integer;
begin
  result:=0;
  if fSolvedGameState.gameBlock.size = 0 then exit;
  for colIndex:=0 to pred(fSolvedGameState.gameBlock[0].size) do
    result:= result + processStepResult(overlapColumn(colIndex));
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
      gameCells.push(TGameCell.create(col,row,cellId,clDefault));
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
  result:=TGameState.create(gameBlock,rowClueBlock,columnClueBlock);
end;


//Solve runner which calls each method in turn and deals with changes
function TNonogramSolver.solve: TGameState;
var
  changesOnCurrentLoop:integer;
begin
  fSolvedGameState:=copyGameState(fInitialState);
    repeat
    changesOnCurrentLoop:=0;
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapRows;
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapColumns;
    until changesOnCurrentLoop = 0;
  //now update fSolvedGame with the stored stateChanges

  result:=fSolvedGameState;
end;

end.
