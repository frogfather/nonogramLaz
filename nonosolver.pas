unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameStateChange,gameBlock,gameCell,
  enums,graphics,arrayUtils,clueCell,iNonoSolver;
type
  
  { TNonogramSolver }

  TNonogramSolver = class(TInterfacedObject,INonogramSolver)
    private
    fInitialState:TGameState;
    fSolvedGameState:TGameState;
    fChanges:TGameStateChanges;
    function overlapRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function overlapColumn(gameState:TGameState;columnId:integer):TGameStateChanges;
    function overlapRows(gameState:TGameState):integer;
    function overlapColumns(gameState:TGameState):integer;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    function applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
    function addClueToBlock(clues:TClueCells;currentLength,index:integer):integer;
    function removeClueFromBlock(clues:TClueCells;currentLength,index:integer):integer;
    function getGameCellColumn(gameState:TGameState;column:integer):TGameCells;
    public
    function solve(initialState:TGameState):TGameState; //should be some kind of result object
  end;

implementation

{ TNonogramSolver }


{ Solve methods to be run repeatedly until there are no changes}

function TNonogramSolver.overlapRow(gameState:TGameState;rowId: integer): TGameStateChanges;
var
  clues:TClueCells;
  gameRow:TGameCells;
  cell:TGameCell;
  clueIndex,columnId:integer;
  cluesLengthBefore,cluesLengthAfter:integer;
  minRight,maxleft:integer;
begin
  clues:=GameState.rowClues[rowId];
  gameRow:=gameState.gameBlock[rowId];
  result:=TGameStateChanges.create;
  if clues.size = 0 then exit;
  cluesLengthAfter:=0;
  cluesLengthBefore:=0;

  //first add all the clues to cluesLengthAfter
  for clueIndex:= 0 to pred(clues.size) do
    cluesLengthAfter:=addClueToBlock(clues,cluesLengthAfter,clueIndex);

  for clueIndex:= pred(clues.size) downTo 0 do
    begin
    maxLeft:=succ(gameRow.size) - cluesLengthAfter;
    cluesLengthAfter:= removeClueFromBlock(clues,cluesLengthAfter,clueIndex);
    cluesLengthBefore:=addClueToBlock(clues,cluesLengthBefore,clueIndex);
    minRight:=cluesLengthBefore;

    if (maxLeft <= minRight) then
      for columnId:= (maxLeft-1) to (minRight-1) do
        begin
        cell:=gameState.gameBlock[rowId][columnId];
        if (cell.fill = cfEmpty)
          then result.push(TGameStateChange.create(ctGame,columnId,rowId,
                                                   cfFill,cell.fill,
                                                   clues[clueIndex].colour,
                                                   cell.colour))
          else writeln('cell '+rowId.toString+','+columnId.ToString+' has not changed');
        end;
    end;
end;

function TNonogramSolver.overlapColumn(gameState:TGameState;columnId: integer): TGameStateChanges;
var
  clues:TClueCells;
  gameColumn:TGameCells;
  clueIndex,rowId:integer;
  cell:TGameCell;
  rowIndex:integer;
  cluesLengthAbove,cluesLengthBelow:integer;
  minBottom,maxTop:integer;
begin
  gameColumn:=getGameCellColumn(gameState,columnId);
  clues:=GameState.columnClues[columnId];
  result:=TGameStateChanges.create;
    //first add all the clues to cluesLengthAfter
  cluesLengthAbove:=0;
  cluesLengthBelow:=0;
  for clueIndex:= 0 to pred(clues.size) do
    cluesLengthBelow:=addClueToBlock(clues,cluesLengthBelow,clueIndex);

  for clueIndex:= pred(clues.size) downTo 0 do
    begin
    maxTop:=succ(gameColumn.size) - cluesLengthBelow;
    cluesLengthBelow:= removeClueFromBlock(clues,cluesLengthBelow,clueIndex);
    cluesLengthAbove:=addClueToBlock(clues,cluesLengthAbove,clueIndex);
    minBottom:=cluesLengthAbove;

    if (maxTop <= minBottom) then
      for rowId:= (maxTop-1) to (minBottom-1) do
        begin
        cell:=gameState.gameBlock[rowId][columnId];
        if (cell.fill = cfEmpty)
          then result.push(TGameStateChange.create(ctGame,columnId,rowId,
                                                   cfFill,cell.fill,
                                                   clues[clueIndex].colour,
                                                   cell.colour))
          else writeln('cell '+rowId.toString+','+columnId.ToString+' has not changed');
        end;
    end;

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
  writeln('step result is '+stepResult.size.toString);
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

//TODO - move this somewhere common so that the game can access it
function TNonogramSolver.applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
var
  index:integer;
  change:TGameStateChange;
begin
  //update the game object with the changes
  for index:=0 to pred(gameStateChanges.size) do
    begin
    change:=gameStateChanges[index];
    if (change.cellType = ctGame) then
      begin
      GameState.gameBlock[change.row][change.column].fill:=change.cellFillMode;
      GameState.gameBlock[change.row][change.column].colour:=change.colour;
      end; //todo: clues
    end;
  result:=gameState;
end;

function TNonogramSolver.addClueToBlock(clues: TClueCells; currentLength,
  index: integer): integer;
begin
  result:= currentLength + clues[index].value;
  if (index < pred(clues.size))
    and (clues[index].colour = clues[index+1].colour)
    then result:=result + 1;
end;

function TNonogramSolver.removeClueFromBlock(clues: TClueCells; currentLength,
  index: integer): integer;
begin
  result:= currentlength - clues[index].value;
  if (index > 0)
    and (clues[index].colour = clues[index-1].colour)
    then result:= result - 1;
end;

function TNonogramSolver.getGameCellColumn(gameState:TGameState;column: integer): TGameCells;
var
  rowIndex:integer;
begin
  result:=TGameCells.create;
  for rowIndex:= 0 to pred(GameState.gameBlock.size) do
    result.push(GameState.gameBlock[rowIndex][column]);
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
    solvedGameState:=applyChanges(solvedGameState,fChanges);;
    until changesOnCurrentLoop = 0;
  result:=solvedGameState;
end;

//Some useful methods



end.

