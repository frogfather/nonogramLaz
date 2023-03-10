unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameStateChange,gameBlock,gameCell,
  enums,graphics,arrayUtils,clueCell,iNonoSolver,gameSpace,clueBlock;
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

    function edgeProximityRows(gameState:TGameState):integer;
    function edgeProximityColumns(gameState:TGameState):integer;
    function edgeProximityRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function edgeProximityColumn(gameState:TGameState;columnId:integer):TGameStateChanges;

    function generateChanges(gameState:TGameState;rowStart,rowEnd,colStart,colEnd:Integer;fill:ECellFillMode=cfFill;fillColour:TColor=clBlack):TGameStateChanges;
    function clueInSpace(spaces:TGameSpaces;clue:TClueCell):integer;
    function getAllowedCluesForCurrentSpace(spaces:TGameSpaces;spaceIndex:integer):TClueCells;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    function applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
    function setClueCandidates(spaces: TGameSpaces;clues:TClueCells):TGameSpaces;
    function getSpacesForGameCells(gameCells_:TGameCells):TGameSpaces;
    function getSequenceLength(cells_:TGameCells;start_:integer;backwards_:boolean=false):integer;
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
var
  rowClues_:TClueCells;
  rowCells_:TGameCells;
  clueIndex,cellIndex:integer;
begin
  result:=TGameStateChanges.create;
  rowClues_:=gameState.rowClues[rowId];
  rowCells_:=gameState.gameBlock[rowId];
  //First, if the filled cells count matches the total of the clues we can
  //fill in all unfilled spaces with crosses
  if (rowClues_.clueSum = rowCells_.filledCells)
    then
      begin
      writeln('Row '+rowId.toString+' complete. Generate changes for row '+rowId.ToString);
      result.concat(generateChanges(gameState,rowId,rowId,0,pred(rowCells_.size),cfCross));
      end;
  //Next, look for clues that are the maximum size they can be
  //Need to think about this
  //for a given filled in cell, which clues could this be?
  //what size is it?
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

//If the first clue is (eg) value 2 and the third cell from the edge is filled in
//then the first cell must be empty
function TNonogramSolver.edgeProximityRows(gameState: TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  for rowIndex:=0 to pred(GameState.gameBlock.size) do
    result:= result + processStepResult(edgeProximityRow(gameState,rowIndex));
end;

function TNonogramSolver.edgeProximityColumns(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameBlock.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameBlock[0].size) do
    result:= result + processStepResult(edgeProximityColumn(gameState,colIndex));
end;

function TNonogramSolver.edgeProximityRow(gameState: TGameState; rowId: integer
  ): TGameStateChanges;
var
  cells:TGameCells;
  clues:TClueCells;
  firstClue,lastClue:TClueCell;
  firstFilledSequenceStart,firstFilledSequenceLength:integer;
  lastFilledSequenceStart,lastFilledSequenceLength:integer;
  mustCrossEnd,mustCrossStart:integer;
  sequenceColour:TColor;
begin
  result:=TGameStateChanges.create;
  cells:=gameState.gameBlock[rowId];
  clues:=gameState.rowClues[rowId];
  firstClue:=clues[pred(clues.size)];
  lastClue:=clues[0];
  firstFilledSequenceStart:=cells.firstFilled;
  firstFilledSequenceLength:=getSequenceLength(cells, firstFilledSequenceStart);
  lastFilledSequenceStart:=cells.lastFilled;
  lastFilledSequenceLength:=getSequenceLength(cells,lastFilledSequenceStart,true);
  if (firstFilledSequenceStart > -1) then
    begin
    sequenceColour:=cells[firstFilledSequenceStart].colour;
    if (firstFilledSequenceStart < firstClue.value + 1)
      and (sequenceColour = firstClue.colour) then
      begin
      mustCrossStart:=0;
      mustCrossEnd:=(firstFilledSequenceStart + firstFilledSequenceLength -(firstClue.value + 1));
      //cells that must be filled
      result.concat(
        generateChanges(
          gameState,rowId,rowId,firstFilledSequenceStart, firstClue.value - 1,cfFill,sequenceColour));
      //cells that cannot be filled
      result.concat(
        generateChanges(
          gameState,rowId,rowId,mustCrossStart,mustCrossEnd,cfCross));
      end;
    end;
  if (lastFilledSequenceStart > - 1) then
    begin
    sequenceColour:=cells[lastFilledSequenceStart].colour;
    //sums a little more complicated here
    if ((cells.size - (lastFilledSequenceStart + 1)) < (lastClue.value +1))
      and (sequenceColour = lastClue.colour) then
      begin
      mustCrossStart:=lastFilledSequenceStart - (lastFilledSequenceLength - 1)+lastClue.value;
      mustCrossEnd:=pred(cells.size);
      //cells that must be filled
      result.concat(
        generateChanges(
          gameState,rowId,rowId, (cells.size - lastClue.value),lastFilledSequenceStart,cfFill,sequenceColour));
      //cells that cannot be filled
      result.concat(
        generateChanges(
          gameState,rowId,rowId, mustCrossStart,mustCrossEnd,cfCross));
      end;
    end;
end;

function TNonogramSolver.edgeProximityColumn(gameState: TGameState;
  columnId: integer): TGameStateChanges;
var
  cells:TGameCells;
  clues:TClueCells;
  firstClue,lastClue:TClueCell;
  firstFilledSequenceStart,firstFilledSequenceLength:integer;
  lastFilledSequenceStart,lastFilledSequenceLength:integer;
  mustCrossEnd,mustCrossStart:integer;
  sequenceColour:TColor;
begin
  result:=TGameStateChanges.create;
  cells:=gameState.gameBlock.getColumn(columnId);
  clues:=gameState.columnClues[columnId];
  firstClue:=clues[pred(clues.size)];
  lastClue:=clues[0];
  firstFilledSequenceStart:=cells.firstFilled;
  firstFilledSequenceLength:=getSequenceLength(cells, firstFilledSequenceStart);
  lastFilledSequenceStart:=cells.lastFilled;
  lastFilledSequenceLength:=getSequenceLength(cells,lastFilledSequenceStart,true);
  if (firstFilledSequenceStart > -1) then
    begin
    sequenceColour:=cells[firstFilledSequenceStart].colour;
    if (firstFilledSequenceStart < firstClue.value + 1)
      and (sequenceColour = firstClue.colour) then
      begin
      mustCrossStart:=0;
      mustCrossEnd:=(firstFilledSequenceStart + firstFilledSequenceLength -(firstClue.value + 1));
      //cells that must be filled
      result.concat(
        generateChanges(
          gameState,firstFilledSequenceStart, firstClue.value - 1,columnId,columnId,cfFill,sequenceColour));
      //cells that cannot be filled
      result.concat(
        generateChanges(
          gameState,mustCrossStart,mustCrossEnd,columnId,columnId,cfCross));
      end;
    end;
  if (lastFilledSequenceStart > - 1) then
    begin
    sequenceColour:=cells[lastFilledSequenceStart].colour;
    //sums a little more complicated here
    if ((cells.size - (lastFilledSequenceStart + 1)) < (lastClue.value +1))
      and (sequenceColour = lastClue.colour) then
      begin
      mustCrossStart:=lastFilledSequenceStart - (lastFilledSequenceLength - 1)+lastClue.value;
      mustCrossEnd:=pred(cells.size);
      //cells that must be filled
      result.concat(
        generateChanges(
          gameState,(cells.size - lastClue.value),lastFilledSequenceStart,columnId,columnId,cfFill,sequenceColour));
      //cells that cannot be filled
      result.concat(
        generateChanges(
          gameState,mustCrossStart,mustCrossEnd,columnId,columnId,cfCross));
      end;
    end;
end;

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
  emptySpaces,spaces:TGameSpaces;
  clueSpaceIndex:integer;
  colStart,colEnd:integer;
begin
  clues:=GameState.rowClues[rowId];
  result:=TGameStateChanges.create;
  writeln('spaces for row '+rowId.toString);
  emptySpaces:=getSpacesForGameCells(gameState.gameBlock[rowId]);
  spaces:= setClueCandidates(emptySpaces,clues);

  if clues.size = 0 then exit;

  for clueIndex:=pred(clues.size) downto 0 do
    begin
    clueSpaceIndex:=clueInSpace(spaces,clues[clueIndex]);
    if (clueSpaceIndex > -1) then
      begin
      currentSpace:= spaces[clueSpaceIndex];
      allowedCluesForCurrentSpace:=getAllowedCluesForCurrentSpace(spaces,clueSpaceIndex);

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
        colStart:=Spaces[clueSpaceIndex].startPos+limits.Y - 1;
        colEnd:=spaces[clueSpaceIndex].startPos + limits.X - 1;
        result.concat(
          generateChanges(gameState,rowId,rowId,
            colStart,colEnd,cfFill,clues[clueIndex].colour));
        end;
      end;
    end;
  //5 deal with empty spaces - ones that can have no clues
  for spaceIndex:= 0 to pred(spaces.size) do
    begin
    writeln('row '+rowId.toString+' space '+spaceIndex.toString+' has candidates '+spaces[spaceIndex].candidates.join(','));
    if (spaces[spaceIndex].candidates.size = 0) then
      begin
      colStart:=spaces[spaceIndex].startPos;
      colEnd:=spaces[spaceIndex].endPos;
      result.concat(
        generateChanges(
          gameState,rowId,rowId,colStart,colEnd,cfCross));
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
  emptySpaces,spaces:TGameSpaces;
  rowStart,rowEnd:Integer;
begin
  clues:=GameState.columnClues[columnId];
  gameCells:=gameState.gameBlock.getColumn(columnId);
  result:=TGameStateChanges.create;
  writeln('spaces for col '+columnId.toString);
  emptySpaces:=getSpacesForGameCells(gameCells);

  if clues.size = 0 then exit;
  spaces:= setClueCandidates(emptySpaces,clues);

  for clueIndex:= pred(clues.size) downto 0 do
    begin
    clueSpaceIndex:=clueInSpace(spaces,clues[clueIndex]);

    if (clueSpaceIndex > -1) then
      begin
      currentSpace:= spaces[clueSpaceIndex];
      allowedCluesForCurrentSpace:=getAllowedCluesForCurrentSpace(spaces,clueSpaceIndex);

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
        rowStart:=Spaces[clueSpaceIndex].startPos+limits.Y - 1;
        rowEnd:=spaces[clueSpaceIndex].startPos + limits.X - 1;
        result.concat(
          generateChanges(gameState,rowStart,
            rowEnd,columnId,columnId, cfFill,clues[clueIndex].colour));
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
      rowStart:=spaces[spaceIndex].startPos;
      rowEnd:=spaces[spaceIndex].endPos;
      result.concat(
        generateChanges(gameState,rowStart,rowEnd,columnId,columnId,cfCross));
      end;
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

function TNonogramSolver.setClueCandidates(spaces: TGameSpaces;
  clues: TClueCells):TGameSpaces;
var
  clueIndex,spaceIndex,clueCurrentlyAt,lastSpaceClueWillFit:integer;
  spaceClueBlock:TSpaceClueBlock;
  lastAllowedSpace:integer;
  currentClue:TClueCell;
  spaceFound,done:boolean;
begin
  //1) Add clues to the first space until no more will fit then move on to the next space
  //until no more clues
  result:=TGameSpaces.create;
  for spaceIndex:=0 to pred(spaces.size) do
    result.push(spaces[spaceIndex]);
  spaceIndex:=0;
  lastAllowedSpace:=pred(result.size);
  for clueIndex:=pred(clues.size) downto 0 do
    begin
    currentClue:= clues[clueIndex];
    done:=false;
    //find a space it'll fit in
    while not done do
      begin
      spaceFound:= (currentClue.value <= result[spaceIndex].freeSpace);
      if not spaceFound then spaceIndex:=spaceIndex+1;
      done:=spaceFound or (spaceIndex > lastAllowedSpace);
      end;

    if spaceFound then
      begin
      writeln('clue '+clueIndex.toString+' value '+currentClue.value.toString+' will fit in space '+spaceIndex.toString+' size '+result[spaceIndex].freeSpace.toString);
      result[spaceIndex].candidates.push(currentClue);
      //create a block corresponding to this clue
      spaceClueBlock:=TSpaceClueBlock.Create(clueIndex,currentClue.value);
      if (clueIndex > 0) and (currentClue.colour = clues[clueIndex - 1].colour)
        then spaceClueBlock.spaceRight:=1;
      result[spaceIndex].blocks.push(spaceClueBlock);
      end else
      begin
      writeln('Raise an error - no space for clues');
      end;
    end;

  //now we find the last clue block and move it to the right until we get
  //to the last space that can hold it.
  for clueIndex:=0 to pred(clues.size) do
    begin
    //Find the space that has that clue in it
    clueCurrentlyAt:=lastAllowedSpace;
    while result[clueCurrentlyAt].candidates.indexOf(clues[clueIndex]) = -1 do
      clueCurrentlyAt:=clueCurrentlyAt -1;

    //If there are further spaces, see if the clue will fit
    if clueCurrentlyAt < lastAllowedSpace then
      begin
      lastSpaceClueWillFit:=clueCurrentlyAt;
      for spaceIndex:=clueCurrentlyAt + 1 to lastAllowedSpace do
        begin
        if clues[clueIndex].value <= result[spaceIndex].freeSpace then
          begin
          writeln('clue '+clueIndex.toString+' value '+clues[clueIndex].value.toString+' will fit in space '+spaceIndex.toString+' size '+result[spaceIndex].freeSpace.toString);
          lastSpaceClueWillFit:=spaceIndex;
          result[spaceIndex].candidates.push(clues[clueIndex]);
          end;
        end;
      //If the last space the clue will fit is not where it currently is then
      //remove it from the old position and add it to the new one
      if (lastSpaceClueWillFit <> clueCurrentlyAt) then
        begin
        //remove the clue from its last position
        result[clueCurrentlyAt].blocks.delete(clueIndex);
        //and add it to the new position
        spaceClueBlock:=TSpaceClueBlock.create(clueIndex,clues[clueIndex].value);
        //If there's a previous block of the same colour then there should be a space to its left
        if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex+1].colour)
          then spaceClueBlock.spaceLeft:=1;
        result[lastSpaceClueWillFit].blocks.push(spaceClueBlock);

        lastAllowedSpace:=lastSpaceClueWillFit;
        end;
      end;
    end;

end;

function TNonogramSolver.getSpacesForGameCells(gameCells_: TGameCells
  ): TGameSpaces;
var
  index:integer;
  startBlock,endBlock:integer;
begin
  result:=TGameSpaces.create;
  startBlock:=-1;
  endBlock:=-1;
  for index:=0 to gameCells_.size do
    begin
    if (index < gameCells_.size) and (gameCells_[index].fill <> cfCross) then
      begin
      if startBlock = -1 then
        begin
        startBlock:=index;
        endBlock:=index;
        end
      else endBlock:=endBlock + 1;
      end else if (endBlock > -1) then
      begin
      result.push(TGameSpace.Create(startBlock,endBlock));
      startBlock:=-1;
      endBlock:=-1;
      end;
    end;
end;

function TNonogramSolver.getSequenceLength(cells_: TGameCells; start_: integer;backwards_:boolean): integer;
var
  index:integer;
  sequenceColour:TColor;
  sequenceEnd:boolean;
begin
  result:=0;
  if (start_ = -1)or(start_ > pred(cells_.size)) then exit;
  index:=start_;
  sequenceEnd:=false;
  if (cells_[index].fill <> cfFill) then exit;
  result:=result+1;
  sequenceColour:=cells_[index].colour;
  repeat
  if backwards_ then index:=index-1 else index:= index+1;
  if (index >= 0)and(index < pred(cells_.size)) and (cells_[index].fill = cfFill)
    and (cells_[index].colour = sequenceColour)
    then result:=result+1 else sequenceEnd:=true;
  until sequenceEnd;
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

    changesOnCurrentLoop:=changesOnCurrentLoop + columnsCluesComplete(solvedGameState);
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

    changesOnCurrentLoop:= changesOnCurrentLoop + edgeProximityRows(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    changesOnCurrentLoop:=changesOnCurrentLoop + columnsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    changesOnCurrentLoop:= changesOnCurrentLoop + edgeProximityColumns(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    changesOnCurrentLoop:= changesOnCurrentLoop + rowsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    changesOnCurrentLoop:=changesOnCurrentLoop + columnsCluesComplete(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);

    writeln('end loop '+loopCounter.tostring+' ----------------');
    loopCounter:=loopCounter+1;
    until changesOnCurrentLoop = 0;
  result:=solvedGameState;
end;

//Some useful methods



end.

