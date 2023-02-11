unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameBlock,gameCell,
  enums,graphics,arrayUtils,clueCell,iNonoSolver;
type
  
  { TNonogramSolver }

  TNonogramSolver = class(TInterfacedObject,INonogramSolver)
    private
    fInitialState:TGameState;
    fSolvedGameState:TGameState;
    fChanges:TGameStateChanges;
    fMultiColour:boolean;
    function overlapRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function overlapColumn(gameState:TGameState;columnId:integer):TGameStateChanges;
    function overlapRows(gameState:TGameState):integer;
    function overlapColumns(gameState:TGameState):integer;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    property multiColour:boolean read fMulticolour;
    public
    constructor create(isMultiColour:boolean=false);
    function solve(initialState:TGameState):TGameState; //should be some kind of result object
  end;

implementation

{ TNonogramSolver }


{ Solve methods to be run repeatedly until there are no changes}

function TNonogramSolver.overlapRow(gameState:TGameState;rowId: integer): TGameStateChanges;
var
  clues:TClueCells;
  gameRow:TGameCells;
  clueIndex,columnId:integer;
  cluesLengthBefore,cluesLengthAfter:integer;
  minRight,maxleft:integer;
  spaceBetweenClues:integer;
begin
  writeLn('----------------------');
  writeln('row '+rowId.toString);
  clues:=GameState.rowClues[rowId];
  gameRow:=gameState.gameBlock[rowId];
  result:=TGameStateChanges.create;
  if clues.size = 0 then exit;
  cluesLengthAfter:=0;
  cluesLengthBefore:=0;
  if multicolour then spaceBetweenClues:=0 else spacebetweenClues:=1;
  //cluesLengthAfter initially length of all clues without spaces
  for clueIndex:= 0 to pred(clues.size) do
    begin
    cluesLengthAfter:=cluesLengthAfter + clues[clueIndex].value;
    if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex+1].colour)
      then cluesLengthAfter:=cluesLengthAfter + 1; //add space if the colour is the same
    end;

  for clueIndex:= pred(clues.size) downTo 0 do
    begin
    maxLeft:=succ(gameRow.size) - cluesLengthAfter;

    cluesLengthAfter:= cluesLengthAfter - clues[clueIndex].value;
    if (clueIndex > 0) and (clues[clueIndex].colour = clues[clueIndex-1].colour)
      then cluesLengthAfter:=cluesLengthAfter - 1;

    if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex + 1].colour)
      then cluesLengthBefore:=cluesLengthBefore + 1;
    cluesLengthBefore:=cluesLengthBefore + clues[clueIndex].value;

    minRight:=cluesLengthBefore;

    writeln('Clue '+clueIndex.toString+' maxLeft '+maxLeft.toString+' minRight '+minRight.toString);
    if (maxLeft < minRight) then
      for columnId:= maxLeft to minRight do
        begin
        writeln('row '+rowId.toString+'cell '+columnId.ToString+' must be clue '+clueIndex.toString);
        gameRow[columnId].rowCandidates.push(clues[clueIndex]);
        end;
    end;
end;

function TNonogramSolver.overlapColumn(gameState:TGameState;columnId: integer): TGameStateChanges;
var
  cells:TGameCells;
  clues:TClueCells;
  rowIndex:integer;
begin
  cells:=TGameCells.create;
  //get the cells in a format we can process more easily
  for rowIndex:= 0 to pred(GameState.gameBlock.size) do
    cells.push(GameState.gameBlock[rowIndex][columnId]);
  //get the clues for this column
  clues:=GameState.columnClues[columnId];
  result:=TGameStateChanges.create;
  //process this column to look for overlaps

end;

function TNonogramSolver.overlapRows(gameState:TGameState): integer;
var
  rowIndex:integer;
  clues:TClueCells;
begin
  result:=0;
  //each row of the game block is a row of the puzzle
  for rowIndex:=0 to pred(GameState.gameBlock.size) do
    result:= result + processStepResult(overlapRow(gameState,rowIndex));
end;

function TNonogramSolver.overlapColumns(gameState:TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameBlock.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameBlock[0].size) do
    result:= result + processStepResult(overlapColumn(gameState,colIndex));
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

constructor TNonogramSolver.create(isMultiColour: boolean);
begin
  fMultiColour:=isMultiColour;
end;


//Solve runner which calls each method in turn and deals with changes
function TNonogramSolver.solve(initialState:TGameState): TGameState;
var
  changesOnCurrentLoop:integer;
  solvedGameState:TGameState;
begin
  solvedGameState:=copyGameState(initialState);
    repeat
    changesOnCurrentLoop:=0;
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapRows(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapColumns(solvedGameState);
    until changesOnCurrentLoop = 0;
  //now update solvedGame with the stored stateChanges

  result:=solvedGameState;
end;

end.

