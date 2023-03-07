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
    function clueInSpace(spaces:TGameSpaces;clue:TClueCell):integer;
    function getAllowedCluesForCurrentSpace(spaces:TGameSpaces;spaceIndex:integer):TClueCells;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    function applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
    procedure setClueCandidates(var spaces: TGameSpaces;clues:TClueCells);
    procedure outputCurrentGameState(gameState:TGameState);

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
  result:=TGameStateChanges.create;
  if (gameState.rowClues[rowId].clueSum = gameState.gameBlock[rowId].filledCells)
    then
      begin
      writeln('Row '+rowId.toString+' complete. Generate changes for row '+rowId.ToString);
      result.concat(generateChanges(gameState,rowId,rowId,0,pred(gameState.gameBlock[0].size),cfCross));
      end;
end;

function TNonogramSolver.columnCluesComplete(gameState: TGameState;
  columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
  if (gameState.columnClues[columnId].clueSum = gameState.gameBlock.getColumn(columnId).filledCells)
    then
      begin
      writeln('Column '+columnId.toString+' complete. Generate changes for column '+columnId.ToString);
      result.concat(generateChanges(gameState,0,pred(gameState.gameBlock.size),columnId,columnId,cfCross));
      end;
end;

function TNonogramSolver.generateChanges(gameState: TGameState; rowStart,
  rowEnd, colStart, colEnd: Integer; fill: ECellFillMode; fillColour: TColor
  ): TGameStateChanges;
var
  rowIndex,colIndex:integer;
  cell:TGameCell;
begin
  if (rowStart < 0) or (rowEnd > 14) or (colStart < 0) or (colEnd > 19) then
    begin
    writeln('oops '+rowstart.ToString+':'+colStart.toString);
    exit;
    end;

  result:=TGameStateChanges.create;
  writeln('Generate changes row: '+rowStart.toString+' -> '+rowEnd.ToString+', col: '+colstart.toString+' -> '+colEnd.toString);
  for rowIndex:= rowStart to rowEnd do
  for colIndex:= colStart to colEnd do
    begin
    cell:=gameState.gameBlock[rowIndex][colIndex];
    if (cell.fill = cfEmpty)
      then result.push(TGameStateChange.create(ctGame,colIndex,rowIndex,
                                                     fill,cell.fill,
                                                     fillColour,
                                                     cell.colour));
    end;
end;

function TNonogramSolver.clueInSpace(spaces: TGameSpaces; clue: TClueCell
  ): integer;
var
  clueSpaceCount,spaceIndex,clueSpaceIndex:integer;
begin
  clueSpaceCount:=0;
  clueSpaceIndex:=-1;
  for spaceIndex:=0 to pred(spaces.size) do
    begin
    if (spaces[spaceIndex].candidates.indexOf(clue)> -1)
      then
      begin
      if (clueSpaceCount = 0) then clueSpaceIndex:= spaceIndex;
      clueSpaceCount:=clueSpaceCount + 1;
      end;
    end;
  if clueSpaceCount = 1 then result:=clueSpaceIndex else result:=-1;
end;

function TNonogramSolver.getAllowedCluesForCurrentSpace(spaces:TGameSpaces;spaceIndex:integer): TClueCells;
var
  spaceId,clueIndex,duplicateIndex:integer;
begin
  //returns clues that can only be in this space. Place in reverse order
  result:=TClueCells.create;
  if (spaces.size = 0) then exit;
  for clueIndex:=pred(spaces[spaceIndex].candidates.size) downto 0 do
    result.push(spaces[spaceIndex].candidates[clueIndex]);

  //now look at the other spaces and remove any candidates that are there too.
  for spaceId:=0 to pred(spaces.size) do
    if (spaceId <> spaceIndex) then
      for clueIndex:=0 to pred(spaces[spaceId].candidates.size) do
      begin
      duplicateIndex:= result.indexOf(spaces[spaceId].candidates[clueIndex]);
      if (duplicateIndex > -1)
        then result.delete(duplicateIndex)
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
  allowedCluesForCurrentSpace:TClueCells;
  currentSpace:TGameSpace;
  clueIndex,spaceIndex:integer;
  limits,limitsForSpace:TPoint;
  spaces:TGameSpaces;
  clueSpaceIndex:integer;

  //for testing
  allowedClueId:integer;
  allowedCluesOutput:string;
begin
  //1 setup
  clues:=GameState.rowClues[rowId];
  result:=TGameStateChanges.create;
  writeln('spaces for row '+rowId.toString);
  spaces:=gameState.gameBlock[rowId].spaces;

  //2 Cases where there are no clues or no spaces
  if clues.size = 0 then exit;
  //3 work out which clues can go in which spaces
  setClueCandidates(spaces,clues);


  //4 look at clues that can only be in one space. Work out limits
  //The situation where there is only one space is a subset of this
  for clueIndex:=pred(clues.size) downto 0 do
    begin
    clueSpaceIndex:=clueInSpace(spaces,clues[clueIndex]);
    if (clueSpaceIndex > -1) then
      begin
      currentSpace:= spaces[clueSpaceIndex];
      allowedCluesForCurrentSpace:=getAllowedCluesForCurrentSpace(spaces,clueSpaceIndex);

      //for testing
      allowedCluesOutput:='Allowed clues for row '+rowId.tostring+' space '+clueSpaceIndex.toString+': ';
      for allowedClueId:=0 to pred(allowedCluesForCurrentSpace.size)do
        begin
        allowedCluesOutput:=allowedCluesOutput+allowedCluesForCurrentSpace[allowedClueId].index.toString+' ';
        end;
      writeln(allowedCluesOutput);
      limits:= clues.limits(allowedCluesForCurrentSpace,currentSpace.spaceSize, clueIndex);
      if (limits.Y <= limits.X) then
        begin
        //if the limits adjusted for the space are outside the space then quit
        limitsForSpace:=TPoint.Create(currentSpace.startPos + limits.X - 1,currentSpace.startPos+limits.Y - 1);
        writeln('limits for clue '+clueIndex.toString+' in space '+clueSpaceIndex.toString+' in row '+rowId.toString+' : '+limitsForSpace.X.toString+':'+limitsForSpace.Y.tostring);

        if (limitsForSpace.X < currentSpace.startPos)
          or (limitsForSpace.X > currentSpace.endPos)
          or (limitsForSpace.Y < currentSpace.startPos)
          or (limitsForSpace.Y > currentSpace.endPos)
          then
            begin
            writeln('clue '+clueIndex.toString+' does not fit in space '+clueSpaceIndex.toString+' on row '+rowId.toString);
            exit;
            end;
        //This is too simplistic as it doesn't take into account already filled cells

        result.concat(
        generateChanges(
          gameState,rowId,rowId,
          Spaces[clueSpaceIndex].startPos+limits.Y - 1,
          spaces[clueSpaceIndex].startPos + limits.X - 1,cfFill,clues[clueIndex].colour));
        end;
      end;
    end;
  //5 deal with empty spaces - ones that can have no clues
  for spaceIndex:= 0 to pred(spaces.size) do
    begin
    writeln('row '+rowId.toString+' space '+spaceIndex.toString+' has candidates '+spaces[spaceIndex].candidates.join(','));
    if (spaces[spaceIndex].candidates.size = 0) then
      begin
      result.concat(
        generateChanges(
          gameState,rowId,rowId,spaces[spaceIndex].startPos,spaces[spaceIndex].endPos,cfCross));
      end;
    end;
end;

function TNonogramSolver.overlapColumn(gameState:TGameState;columnId: integer): TGameStateChanges;
var
  clues:TClueCells;
  allowedCluesForCurrentSpace:TClueCells;
  currentSpace:TGameSpace;
  gameCells:TGameCells;
  clueIndex,clueSpaceIndex,spaceIndex:integer;
  limits,limitsForSpace:TPoint;
  spaces:TGameSpaces;
  //for testing
  allowedClueId:integer;
  allowedCluesOutput:string;
begin
  clues:=GameState.columnClues[columnId];
  gameCells:=gameState.gameBlock.getColumn(columnId);
  result:=TGameStateChanges.create;
  writeln('spaces for col '+columnId.toString);
  spaces:=gameCells.spaces;


  if clues.size = 0 then exit;
  //3 work out which clues can go in which spaces
  setClueCandidates(spaces,clues);

  //4 look at clues that can only be in one space. Work out limits
  //The situation where there is only one space is a subset of this
  for clueIndex:= pred(clues.size) downto 0 do
    begin
    clueSpaceIndex:=clueInSpace(spaces,clues[clueIndex]);

    if (clueSpaceIndex > -1) then
      begin
      currentSpace:= spaces[clueSpaceIndex];
      allowedCluesForCurrentSpace:=getAllowedCluesForCurrentSpace(spaces,clueSpaceIndex);

      //for testing
      allowedCluesOutput:='Allowed clues for column '+columnId.tostring+' space '+clueSpaceIndex.toString+': ';
      for allowedClueId:=0 to pred(allowedCluesForCurrentSpace.size)do
        begin
        allowedCluesOutput:=allowedCluesOutput+allowedCluesForCurrentSpace[allowedClueId].index.toString+' ';
        end;
      writeln(allowedCluesOutput);

      limits:= clues.limits(allowedCluesForCurrentSpace,spaces[clueSpaceIndex].spaceSize, clueIndex);
      if (limits.Y <= limits.X) then
      begin
        begin
        //if the limits adjusted for the space are outside the space then quit
        limitsForSpace:=TPoint.Create(currentSpace.startPos + limits.X - 1,currentSpace.startPos+limits.Y - 1);
        writeln('limits for clue '+clueIndex.toString+' in space '+clueSpaceIndex.toString+' in column '+columnId.toString+' : '+limitsForSpace.X.toString+':'+limitsForSpace.Y.tostring);
        if (limitsForSpace.X < currentSpace.startPos)
          or (limitsForSpace.X > currentSpace.endPos)
          or (limitsForSpace.Y < currentSpace.startPos)
          or (limitsForSpace.Y > currentSpace.endPos)
          then
            begin
            writeln('clue '+clueIndex.toString+' does not fit in space '+clueSpaceIndex.toString+' on column '+columnId.toString);
            exit;
            end;

        result.concat(
        generateChanges(
          gameState,
          Spaces[clueSpaceIndex].startPos+limits.Y - 1,
          spaces[clueSpaceIndex].startPos + limits.X - 1,columnId,columnId, cfFill,clues[clueIndex].colour));
        end;
      end;
    end;
    end;
  //5 deal with empty spaces - ones that can have no clues
  for spaceIndex:= 0 to pred(spaces.size) do
    begin
    writeln('Column '+columnId.toString+' space '+spaceIndex.toString+' has candidates '+spaces[spaceIndex].candidates.join(','));
    if (spaces[spaceIndex].candidates.size = 0) then
      begin
      result.concat(
        generateChanges(
          gameState,spaces[spaceIndex].startPos,spaces[spaceIndex].endPos,columnId,columnId,cfCross));
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

procedure TNonogramSolver.setClueCandidates(var spaces: TGameSpaces;
  clues: TClueCells);
var
  spaceIndex,clueIndex,spaceOfLastClue,lastFreeSpace:integer;
  nomoreClues,noPreviousClues:boolean;
  spaceWithRoomFound,allSpacesChecked,previousClueFound:boolean;
  freeSpaces:TIntArray;
  //change this to an array of objects that have a
  //value and a space before and a space after

  //for testing
  testIndex:integer;
  testOutput:string;
begin
  // 0 Initialise
  freeSpaces:=TIntArray.create;
  lastFreeSpace:=pred(spaces.size);//The last space we can put any clue in

  //1) setup sizes
  for spaceIndex:= 0 to pred(spaces.size) do
    freeSpaces.push(1 + spaces[spaceIndex].endPos - spaces[spaceIndex].startPos);

  //2) add clues to first space until no more room
  // then move to next space etc until no more clues- remember clues in reverse order
  spaceIndex:=0;
  clueIndex:=pred(clues.size);
  noMoreClues:=false;
  repeat
  if (clues[clueIndex].value <= freeSpaces[spaceIndex]) then
    begin
    //add it to candidates of the space
    writeln('Setup: clue '+clueIndex.toString+' ('+clues[clueIndex].value.toString+') will fit in space '+spaceIndex.toString);
    spaces[spaceIndex].candidates.push(clues[clueIndex]);
    freeSpaces[spaceIndex]:=freeSpaces[spaceIndex] - clues[clueIndex].value;
    //If the next clue is of the same colour then we need to add a space between them
    if (clueIndex < pred(clues.size))
      and (clues[clueIndex].colour = clues[clueIndex+1].colour)
      then freeSpaces[spaceIndex]:=freeSpaces[spaceIndex] - 1;
    if (clueIndex > 0) then clueIndex:=clueIndex - 1
      else noMoreClues:=true;
    end else
  if (spaceIndex < lastFreeSpace) then spaceIndex:= spaceIndex + 1
    else
      begin
      //this shouldn't happen. it means there's no more space but clues left
      writeln('error - not enough space for clues');
      noMoreClues:=true;
      end;
  until noMoreClues;

  //now the last clue is as far left as it'll go
  //move it to each space to the right that it'll fit into

  for clueIndex:=pred(clues.size) downto 0 do
    begin
    //find the first space (counting from the end) that this clue can fit in
    spaceOfLastClue:=lastFreeSpace;
    while spaces[spaceOfLastClue].candidates.indexOf(clues[clueIndex]) = -1 do
      spaceOfLastClue:=spaceOfLastClue - 1;

    spaceIndex:=spaceOfLastClue;
      repeat
      if (spaceIndex < lastFreeSpace)
      and (clues[clueIndex].value <= freeSpaces[spaceIndex + 1]) then
        begin
        //move the clue out of the current space
        freeSpaces[spaceOfLastClue]:= freeSpaces[spaceOfLastClue] + clues[clueIndex].value;
        //This isn't right because we're adding a space if the next clue is the same colour above
        //if previous clue of same colour add 1
        if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex + 1].colour)
        then freeSpaces[spaceOfLastClue]:=freeSpaces[spaceOfLastClue] + 1;
        //Now move to the next space
        spaceIndex:=spaceIndex + 1;
        //and add the clue to its candidates
        spaces[spaceIndex].candidates.push(clues[clueIndex]);
        //move clue into new space
        freeSpaces[spaceIndex]:=freeSpaces[spaceIndex]-clues[clueIndex].value;
        //if previous clue of same colour, subtract 1
        if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex + 1].colour)
        then freeSpaces[spaceIndex]:=freeSpaces[spaceIndex] - 1;
        end else lastFreeSpace:=spaceIndex; //If this clue won't fit then neither will any of the previous ones
      until spaceIndex >= lastFreeSpace;
      end;

end;

procedure TNonogramSolver.outputCurrentGameState(gameState:TGameState);
var
  rowId,colId:integer;
  currentCell:TGameCell;
  outputRow:string;
begin
  writeLn('');
  writeln('Current game state');
  for rowId:=0 to pred(gameState.gameBlock.size) do
    begin
    outputRow:='';
    for colId:= 0 to pred(gameState.gameBlock[rowId].size) do
      begin
      currentCell:=gameState.gameBlock[rowId][colId];
        case currentCell.fill of
        cfEmpty: outputRow:=outputRow + '_';
        cfFill: outputRow:= outputRow + 'F';
        cfCross: outputRow:=outputRow + 'X';
        end;
      end;
    writeln(outputRow + ' '+rowId.toString);
    end;
end;

//Solve runner which calls each method in turn and deals with changes
function TNonogramSolver.solve(initialState:TGameState): TGameState;
var
  changesOnCurrentLoop:integer;
  solvedGameState:TGameState;
  loopCounter:integer;
begin
  solvedGameState:=copyGameState(initialState);
  loopCounter:=0;
    repeat
    writeln('start loop '+loopCounter.tostring+' --------------');
    changesOnCurrentLoop:=0;
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapRows(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + overlapColumns(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:=changesOnCurrentLoop + columnsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    writeln('end loop '+loopCounter.tostring+' ----------------');
    loopCounter:=loopCounter+1;
    until changesOnCurrentLoop = 0;
  result:=solvedGameState;
end;

//Some useful methods



end.

