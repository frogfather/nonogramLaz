unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameStateChange,gameBlock,gameCell,
  enums,graphics,arrayUtils,clueCell,iNonoSolver,gameSpace;
type
  
  { TNonogramSolver }

  TNonogramSolver = class(TInterfacedObject,INonogramSolver)
    protected
    fInitialState:TGameState;
    fSolvedGameState:TGameState;
    fChanges:TGameStateChanges;

    function overlapRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function overlapColumn(gameState:TGameState;columnId:integer):TGameStateChanges;
    function overlapRows(gameState:TGameState):integer;
    function overlapColumns(gameState:TGameState):integer;

    function rowsCluesComplete(gameState:TGameState):integer;
    function columnsCluesComplete(gameState:TGameState):integer;
    function rowCluesComplete(gameState:TGameState;rowId:Integer):TGameStateChanges;
    function columnCluesComplete(gameState:TGameState;columnId:integer):TGameStateChanges;

    function generateChanges(gameState:TGameState;rowStart,rowEnd,colStart,colEnd:Integer;fill:ECellFillMode=cfFill;fillColour:TColor=clBlack):TGameStateChanges;

    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    function applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
    public
    function solve(initialState:TGameState):TGameState; //should be some kind of result object
  end;

implementation

{ TNonogramSolver }


{ Solve methods to be run repeatedly until there are no changes}

//0 Row complete: does the number of filled cells match the clue total?
//Run after each step to fill in crosses (spaces) and update clue status

function TNonogramSolver.rowsCluesComplete(gameState: TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  for rowIndex:=0 to pred(GameState.gameBlock.size) do
    result:= result + processStepResult(rowCluesComplete(gameState,rowIndex));
end;

function TNonogramSolver.columnsCluesComplete(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameBlock.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameBlock[0].size) do
    result:= result + processStepResult(columnCluesComplete(gameState,colIndex));
end;

function TNonogramSolver.rowCluesComplete(gameState: TGameState; rowId: Integer
  ): TGameStateChanges;
begin
  if (gameState.rowClues[rowId].clueSum = gameState.gameBlock[rowId].filledCells)
    then writeln('row '+rowId.toString+' complete');
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.columnCluesComplete(gameState: TGameState;
  columnId: integer): TGameStateChanges;
begin
  if (gameState.columnClues[columnId].clueSum = gameState.gameBlock.getColumn(columnId).filledCells)
    then writeln('column '+columnId.toString+' complete');
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.generateChanges(gameState: TGameState; rowStart,
  rowEnd, colStart, colEnd: Integer; fill: ECellFillMode; fillColour: TColor
  ): TGameStateChanges;
var
  rowIndex,colIndex:integer;
  cell:TGameCell;
begin
  result:=TGameStateChanges.create;
  for rowIndex:= rowStart to rowEnd do
  for colIndex:= colStart to colEnd do
    begin
    cell:=gameState.gameBlock[rowIndex][colIndex];
    if (cell.fill = cfEmpty)
      then result.push(TGameStateChange.create(ctGame,colIndex,rowIndex,
                                                     cfFill,cell.fill,
                                                     fillColour,
                                                     cell.colour));
    end;
end;


//1 Overlap: for any given clue are the any cells that must be filled in?
function TNonogramSolver.overlapRows(gameState:TGameState): integer;
var
  rowIndex:integer;
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

function TNonogramSolver.overlapRow(gameState:TGameState;rowId: integer): TGameStateChanges;
var
  clues:TClueCells;
  cell:TGameCell;
  clueIndex,columnId,spaceIndex:integer;
  limits:TPoint;
  spaces:TGameSpaces;
  noMoreClues:boolean;
  availableSpace:integer;
  clueSpaceCount:integer;
  clueInSpace:integer;
  fillStart,fillEnd:integer;
begin
  //1 setup
  clues:=GameState.rowClues[rowId];
  result:=TGameStateChanges.create;
  spaces:=gameState.gameBlock[rowId].spaces;
  noMoreClues:=false;

  //2 Cases where there are no clues or no spaces
  if clues.size = 0 then exit;
  //3 work out which clues can go in which spaces
  spaceIndex:=0;
  clueIndex:=0;
  repeat
  availableSpace:= 1 + spaces[spaceIndex].endPos - spaces[spaceIndex].startPos;
  if (clues[clueIndex].value <= availableSpace) then
    begin
    //add it to candidates of the space
    spaces[spaceIndex].candidates.push(clues[clueIndex]);
    availableSpace:=availableSpace - clues[clueIndex].value;
    if (clueIndex < pred(clues.size)) then clueIndex:=clueIndex + 1
      else noMoreClues:=true;
    end else
  if (spaceIndex < pred(spaces.size)) then spaceIndex:= spaceIndex + 1
    else
      begin
      //this shouldn't happen. it means there's no more space but clues left
      writeln('error - not enough space for clues');
      noMoreClues:=true;
      end;
  until noMoreClues;

  //4 look at clues that can only be in one space. Work out limits
  //The situation where there is only one space is a subset of this
  for clueIndex:=0 to pred(clues.size) do
    begin
    //if it's in more than one space then exit
    clueSpaceCount:=0;
    for spaceIndex:=0 to pred(spaces.size) do
      begin
      if (spaces[spaceIndex].candidates.indexOf(clues[clueIndex])> -1)
        then
          begin
          if (clueSpaceCount = 0)
            then clueInSpace:= spaceIndex;
          clueSpaceCount:=clueSpaceCount + 1;
          end;
      end;
    if (clueSpaceCount = 1) then
      begin
      limits:= clues.limits(spaces[clueInSpace].spaceSize, clueIndex);
      if (limits.Y <= limits.X) then
        result.concat(
        generateChanges(
          gameState,rowId,rowId,
          Spaces[clueInSpace].startPos+limits.Y - 1,
          spaces[clueInSpace].startPos + limits.X - 1,cfFill,clues[clueIndex].colour));
      end;
    end;
end;

function TNonogramSolver.overlapColumn(gameState:TGameState;columnId: integer): TGameStateChanges;
var
  clues:TClueCells;
  gameCells:TGameCells;
  clueIndex,rowId:integer;
  cell:TGameCell;
  limits:TPoint;
  spaces:TGameSpaces;
begin
  clues:=GameState.columnClues[columnId];
  gameCells:=gameState.gameBlock.getColumn(columnId);
  result:=TGameStateChanges.create;
  spaces:=gameCells.spaces;
  writeln('Spaces in column '+columnId.toString+' '+spaces.size.toString);
  if clues.size = 0 then exit;
  for clueIndex:=0 to pred(clues.size) do
    begin
    limits:= clues.limits(gameState.gameBlock.size, clueIndex);
    if (limits.Y <= limits.X) then
      for rowId:= (limits.Y-1) to (limits.X-1) do
        begin
        cell:=gameCells[rowId];
        if (cell.fill = cfEmpty)
          then result.push(TGameStateChange.create(ctGame,columnId,rowId,
                                                   cfFill,cell.fill,
                                                   clues[clueIndex].colour,
                                                   cell.colour))
          else writeln('cell '+rowId.toString+','+columnId.ToString+' has not changed');
        end;
    end;

end;

//2 Edge proximity: is the first or last clue positioned such that the edge cell(s) must be crosses?

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

//Solve runner which calls each method in turn and deals with changes
function TNonogramSolver.solve(initialState:TGameState): TGameState;
var
  changesOnCurrentLoop:integer;
  solvedGameState:TGameState;
begin
  solvedGameState:=copyGameState(initialState);
    repeat
    writeln('start loop --------------');
    changesOnCurrentLoop:=0;
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapRows(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapColumns(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + columnsCluesComplete(solvedGameState);

    solvedGameState:=applyChanges(solvedGameState,fChanges);
    writeln('end loop ----------------');
    until changesOnCurrentLoop = 0;
  result:=solvedGameState;
end;

//Some useful methods



end.

