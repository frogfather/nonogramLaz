unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState,gameStateChanges,gameStateChange,gamegrid,gameCell,
  enums,graphics,arrayUtils,clueCell,iNonoSolver,gameSpace,spaceclueblock;
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

    //TODO function name does not describe what this does. Rename!
    function completeCluesRows(gameState:TGameState):integer;
    function completeCluesColumns(gameState:TGameState):integer;
    function completeCluesRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function completeCluesColumn(gameState:TGameState;columnId:integer):TGameStateChanges;

    function forceSpacesRows(gameState:TGameState):integer;
    function forceSpacesColumns(gameState:TGameState):integer;
    function forceSpacesRow(gameState:TGameState;rowId:integer):TGameStateChanges;
    function forceSpacesColumn(gameState:TGameState;columnId:integer):TGameStateChanges;


    function generateChanges(gameState:TGameState;rowStart,rowEnd,colStart,colEnd:Integer;fill:ECellFillMode=cfFill;fillColour:TColor=clBlack):TGameStateChanges;
    function clueInSpace(spaces:TGameSpaces;clue:TClueCell):integer;
    function getAllowedCluesForCurrentSpace(spaces:TGameSpaces;spaceIndex:integer):TClueCells;
    function processStepResult(stepResult:TGameStateChanges):integer;
    function copyGameState(initialState: TGameState):TGameState;
    function applyChanges(gameState:TGameState;gameStateChanges:TGameStateChanges):TGameState;
    function setClueCandidates(spaces: TGameSpaces;clues:TClueCells):TGameSpaces;
    function getSpacesForGameCells(gameCells_:TGameCells):TGameSpaces;
    function getSequenceLength(cells_:TGameCells;start_:integer;backwards_:boolean=false):integer;
    function getLimits(gameCells:TGameCells;allClues,allowedClues:TClueCells;spaceStart,spaceEnd,clueIndex:integer):TPoint;
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
  for rowIndex:=0 to pred(GameState.gameGrid.size) do
    result:= result + processStepResult(rowCluesComplete(gameState,rowIndex));
end;

function TNonogramSolver.columnsCluesComplete(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameGrid.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameGrid[0].size) do
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
  rowCells_:=gameState.gameGrid[rowId];
  if (rowClues_.clueSum = rowCells_.filledCells)
    then
      begin
      writeln('Row '+rowId.toString+' complete. Generate changes for row '+rowId.ToString);
      result.concat(generateChanges(gameState,rowId,rowId,0,pred(rowCells_.size),cfCross));
      //TODO - update apply changes method to handle clue cells
      //Writeln('Generate changes for clue cells for row '+rowId.ToString);
      //for clueIndex:=0 to pred(rowClues_.size) do
      //  result.push(TGamestateChange.create(ctClue,-1,rowId,cfCross,cfEmpty,clBlack,clBlack));
      end;
end;

function TNonogramSolver.columnCluesComplete(gameState: TGameState;
  columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
  if (gameState.columnClues[columnId].clueSum = gameState.gameGrid.getColumn(columnId).filledCells)
    then
      begin
      writeln('Column '+columnId.toString+' complete. Generate changes for column '+columnId.ToString);
      result.concat(generateChanges(gameState,0,pred(gameState.gameGrid.size),columnId,columnId,cfCross));
      end;
end;

//If the first clue is (eg) value 2 and the third cell from the edge is filled in
//then the first cell must be empty
function TNonogramSolver.edgeProximityRows(gameState: TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  for rowIndex:=0 to pred(GameState.gameGrid.size) do
    result:= result + processStepResult(edgeProximityRow(gameState,rowIndex));
end;

function TNonogramSolver.edgeProximityColumns(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameGrid.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameGrid[0].size) do
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
  cells:=gameState.gameGrid[rowId];
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
  cells:=gameState.gameGrid.getColumn(columnId);
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

function TNonogramSolver.completeCluesRows(gameState: TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  for rowIndex:=0 to pred(GameState.gameGrid.size) do
    result:= result + processStepResult(completeCluesRow(gameState,rowIndex));
end;

function TNonogramSolver.completeCluesColumns(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameGrid.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameGrid[0].size) do
    result:= result + processStepResult(completeCluesColumn(gameState,colIndex));
end;

function TNonogramSolver.completeCluesRow(gameState: TGameState; rowId: integer
  ): TGameStateChanges;
var
  cells:TGameCells;
  cellIndex:integer;
  filledSequenceStart,filledSequenceLength,firstCellAfterSequence:integer;
  done:boolean;
  clues:TClueCells;
  clueIndex,spaceIndex:integer;
  emptySpaces,spaces:TGameSpaces;
  spaceFoundForSequence:boolean;
begin
  result:=TGameStateChanges.create;
  cells:= gameState.gamegrid[rowId];
  clues:=gameState.rowClues[rowId];
  emptySpaces:=getSpacesForGameCells(cells);
  spaces:= setClueCandidates(emptySpaces,clues);
  done:=false;
  firstCellAfterSequence:=-1;
  while not done do
    begin
    //Find the sequence of filled cells starting just after the last
    filledSequenceStart:=cells.firstFilled(firstCellAfterSequence);
    done:=filledSequenceStart= -1;
    if not done then
      begin
      filledSequenceLength:=cells.sequenceLength(filledSequenceStart);
      firstCellAfterSequence:=filledSequenceStart + filledSequenceLength;
      //which space is this sequence in?
      spaceIndex:=0;
      spaceFoundForSequence:=false;
        while not spaceFoundForSequence do
          begin
          spaceFoundForSequence:=(spaces[spaceIndex].startPos <= filledSequenceStart)
            and (spaces[spaceIndex].endPos >= filledSequenceStart + filledSequenceLength - 1);
          if not spaceFoundForSequence then spaceIndex:=spaceIndex + 1;
          end;
        //now we've found the space. Which clues can be here?
        //the space has a list of clues that can fit here
        //we can eliminate clues that are shorter than the length of the sequence

      end;
    end;
end;

function TNonogramSolver.completeCluesColumn(gameState: TGameState;
  columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;

end;

//Force spaces: If a given space were filled in, would it result in an
//illegal situation. EG if two single blocks are separated by a single space
//but there is no clue > 3
function TNonogramSolver.forceSpacesRows(gameState: TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  for rowIndex:=0 to pred(GameState.gameGrid.size) do
    result:= result + processStepResult(forceSpacesRow(gameState,rowIndex));
end;

function TNonogramSolver.forceSpacesColumns(gameState: TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameGrid.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameGrid[0].size) do
    result:= result + processStepResult(forceSpacesColumn(gameState,colIndex));
end;

//Start at the beginning of the row
//Find the first sequence of filled cells
//If the first cell were filled in, what would this do?
function TNonogramSolver.forceSpacesRow(gameState: TGameState; rowId: integer
  ): TGameStateChanges;
var
  gameCells:TGameCells;
  clues:TClueCells;
  emptySpaces,spaces:TGameSpaces;
  spaceIndex:integer;
  currentSpace:TGameSpace;
  positionMarker:integer;
  firstSequenceStart,firstSequenceLength:integer;
  nextSequenceStart,nextSequenceLength:integer;
  spaceProcessed:boolean;
begin
  result:=TGameStateChanges.create;
  gameCells:=gameState.gameGrid[rowId];
  clues:=gameState.rowClues[rowId];
  emptySpaces:=getSpacesForGameCells(gameCells);
  spaces:= setClueCandidates(emptySpaces,clues);
  //Examine each space
  for spaceIndex:=0 to pred(spaces.size) do
    begin
    currentSpace:=spaces[spaceIndex];
    //What do we have in this space?
    spaceProcessed:=false;
    positionMarker:=spaces[spaceIndex].startPos - 1;
    while not spaceProcessed do
      begin
      firstSequenceStart:=gameCells.firstFilled(positionMarker);
      firstSequenceLength:=gameCells.sequenceLength(firstSequenceStart);
      positionMarker:=gameCells.firstFree(firstSequenceStart);
      nextSequenceStart:=gameCells.firstFilled(positionMarker);
      nextSequenceLength:=gameCells.sequenceLength(nextSequenceStart);
      spaceProcessed:= (firstSequenceLength = 0 )or(nextSequenceLength = 0)or(positionMarker = -1);
      if not spaceProcessed  then
        begin
        writeln('Row '+rowId.ToString+' space '+spaceIndex.ToString+' sequence1 start '+firstSequenceStart.toString+' length '+firstSequenceLength.toString);
        writeln('sequence2 start '+nextSequenceStart.toString+' length '+nextSequenceLength.toString);
        end;
      end;
    end;
end;

function TNonogramSolver.forceSpacesColumn(gameState: TGameState;
  columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;

end;

function TNonogramSolver.overlapRows(gameState:TGameState): integer;
var
  rowIndex:integer;
begin
  result:=0;
  //each row of the game block is a row of the puzzle
  for rowIndex:=0 to pred(GameState.gameGrid.size) do
    result:= result + processStepResult(overlapRow(gameState,rowIndex));
end;

function TNonogramSolver.overlapColumns(gameState:TGameState): integer;
var
  colIndex:integer;
begin
  result:=0;
  if GameState.gameGrid.size = 0 then exit;
  for colIndex:=0 to pred(GameState.gameGrid[0].size) do
    result:= result + processStepResult(overlapColumn(gameState,colIndex));
end;

function TNonogramSolver.overlapRow(gameState:TGameState;rowId: integer): TGameStateChanges;
var
  clues:TClueCells;
  gameCells:TGameCells;
  allowedCluesForCurrentSpace:TClueCells;
  currentSpace:TGameSpace;
  clueIndex,spaceIndex:integer;
  limitsForSpace:TPoint;
  emptySpaces,spaces:TGameSpaces;
  clueSpaceIndex:integer;
  colStart,colEnd:integer;
begin
  clues:=GameState.rowClues[rowId];
  result:=TGameStateChanges.create;
  gameCells:=gameState.gameGrid[rowId];
  writeln('spaces for row '+rowId.toString);
  emptySpaces:=getSpacesForGameCells(gameCells);
  spaces:= setClueCandidates(emptySpaces,clues);

  if clues.size = 0 then exit;

  for clueIndex:=pred(clues.size) downto 0 do
    begin
    clueSpaceIndex:=clueInSpace(spaces,clues[clueIndex]);
    if (clueSpaceIndex > -1) then
      begin
      currentSpace:= spaces[clueSpaceIndex];
      allowedCluesForCurrentSpace:=getAllowedCluesForCurrentSpace(spaces,clueSpaceIndex);
      writeln('get limits for row '+rowId.ToString+' space '+currentSpace.startPos.toString+':'+currentSpace.endPos.ToString);
      limitsForSpace:=getLimits(gameCells,clues,allowedCluesForCurrentSpace,currentSpace.startPos,currentSpace.endPos,clueIndex);

      if (limitsForSpace.Y <= limitsForSpace.X) then
        begin
        //if the limits adjusted for the space are outside the space then quit
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
        colStart:=limitsForSpace.Y;
        colEnd:=limitsForSpace.X;
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
  gameCells:=gameState.gameGrid.getColumn(columnId);
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
      writeln('get limits for column '+columnId.ToString+' space '+currentSpace.startPos.toString+':'+currentSpace.endPos.ToString);

      limitsForSpace:=getLimits(gameCells,clues,allowedCluesForCurrentSpace,currentSpace.startPos,currentSpace.endPos,clueIndex);

      if (limitsForSpace.Y <= limitsForSpace.X) then
      begin
        begin
        //if the limits adjusted for the space are outside the space then quit
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
        rowStart:=limitsForSpace.Y;
        rowEnd:= limitsForSpace.X;
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
    cell:=gameState.gameGrid[rowIndex][colIndex];
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
  gameGrid:TGameGrid;
  gameCells:TGameCells;
  row,col:integer;
  cellId:TGUID;
  clueValue,clueIndex:integer;
  clueColour:TColor;
  gridIndex,cellIndex:integer;
  rowClueBlock,columnClueBlock:TClueBlock;
  clueCells:TClueCells;
begin
  //game cells
  gameGrid:=TGameGrid.Create;
  gameCells:=TGameCells.Create;
  for gridIndex:= 0 to pred(initialState.gameGrid.size) do
    begin
    setLength(gameCells,0);
    for cellIndex:=0 to Pred(initialState.gameGrid[gridIndex].size) do
      begin
      col:= initialState.gameGrid[gridIndex][cellIndex].col;
      row:= initialState.gameGrid[gridIndex][cellIndex].row;
      cellId:=initialState.gameGrid[gridIndex][cellIndex].cellId;
      gameCells.push(TGameCell.create(col,row,cellId,clDefault));
      end;
    gameGrid.push(gameCells);
    end;
  //row clues
  rowClueBlock:=TClueBlock.Create;
  clueCells:=TClueCells.Create;
  for gridIndex:=0 to pred(initialState.rowClues.size) do
    begin
    setLength(clueCells,0);
    for cellIndex:=0 to pred(initialState.rowClues[gridIndex].size) do
      begin
      row:=initialState.rowClues[gridIndex][cellIndex].row;
      col:=initialState.rowClues[gridIndex][cellIndex].column;
      clueIndex:=initialState.rowClues[gridIndex][cellIndex].index;
      clueValue:=initialState.rowClues[gridIndex][cellIndex].value;
      clueColour:=initialState.rowClues[gridIndex][cellIndex].colour;
      clueCells.push(TClueCell.create(row,col,clueValue,clueIndex,clueColour));
      end;
    rowClueBlock.push(clueCells);
    end;
  //column clues
  columnClueBlock:=TClueBlock.Create;
  for gridIndex:=0 to pred(initialState.columnClues.size) do
    begin
    setLength(clueCells,0);
    for cellIndex:=0 to pred(initialState.columnClues[gridIndex].size) do
      begin
      row:=initialState.columnClues[gridIndex][cellIndex].row;
      col:=initialState.columnClues[gridIndex][cellIndex].column;
      clueIndex:=initialState.columnClues[gridIndex][cellIndex].index;
      clueValue:=initialState.columnClues[gridIndex][cellIndex].value;
      clueColour:=initialState.columnClues[gridIndex][cellIndex].colour;
      clueCells.push(TClueCell.create(row,col,clueValue,clueIndex,clueColour));
      end;
    columnClueBlock.push(clueCells);
    end;
  result:=TGameState.create(gameGrid,rowClueBlock,columnClueBlock);
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
      GameState.gameGrid[change.row][change.column].fill:=change.cellFillMode;
      GameState.gameGrid[change.row][change.column].colour:=change.colour;
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
      result[spaceIndex].candidates.push(currentClue);
      //create a block corresponding to this clue
      spaceClueBlock:=TSpaceClueBlock.Create(clueIndex,currentClue.value);
      if (clueIndex > 0) and (currentClue.colour = clues[clueIndex - 1].colour)
        then spaceClueBlock.spaceRight:=1;
      result[spaceIndex].spaceClueBlocks.push(spaceClueBlock);
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
        result[clueCurrentlyAt].spaceClueBlocks.delete(clueIndex);
        //and add it to the new position
        spaceClueBlock:=TSpaceClueBlock.create(clueIndex,clues[clueIndex].value);
        //If there's a previous block of the same colour then there should be a space to its left
        if (clueIndex < pred(clues.size)) and (clues[clueIndex].colour = clues[clueIndex+1].colour)
          then spaceClueBlock.spaceLeft:=1;
        result[lastSpaceClueWillFit].spaceClueBlocks.push(spaceClueBlock);
        end;
      lastAllowedSpace:=lastSpaceClueWillFit;
      end;
    end;

end;

function TNonogramSolver.getSpacesForGameCells(gameCells_: TGameCells
  ): TGameSpaces;
var
  index:integer;
  startSpace,endSpace:integer;
begin
  result:=TGameSpaces.create;
  startSpace:=-1;
  endSpace:=-1;
  for index:=0 to gameCells_.size do
    begin
    if (index < gameCells_.size) and (gameCells_[index].fill <> cfCross) then
      begin
      if startSpace = -1 then
        begin
        startSpace:=index;
        endSpace:=index;
        end
      else endSpace:=endSpace + 1;
      end else if (endSpace > -1) then
      begin
      result.push(TGameSpace.Create(startSpace,endSpace));
      startSpace:=-1;
      endSpace:=-1;
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

function TNonogramSolver.getLimits(gameCells: TGameCells;
  allClues,allowedClues: TClueCells; spaceStart, spaceEnd, clueIndex: integer): TPoint;
var
  count, currentClueIndex,positionMarker,clueValue:integer;
  clueColour:TColor;
begin
  //return a point where X is the point the specified cell ends if it's as far left as possible
  //and Y is where it starts if it's as far right as it can go.
  //The allowed clues should be in order because anything else would suggest some very faulty logic elsewhere
  result:=Tpoint.Create(spaceStart-1,spaceEnd+1);
  writeln('getLimits allowed clues: '+allowedClues.join(','));
  currentClueIndex:=allowedClues.indexOf(allClues[clueIndex]);
  if (currentClueIndex = -1) then exit;
  positionMarker:= spaceStart -1;
  for count:= pred(allowedClues.size)  downto currentClueIndex do
    begin
    clueValue:=allowedClues[count].value;
    clueColour:=allowedClues[count].colour;
    positionMarker:=positionMarker+ clueValue;
    result.X:= result.X + clueValue;
    writeln('position marker is '+positionMarker.tostring);
    while (positionMarker < spaceEnd)
      and (gameCells[positionMarker + 1].fill = cfFill)
      and (gameCells[positionMarker + 1 ].colour = cluecolour) do
        begin
        positionMarker:=positionMarker+1;
        result.X:=result.X + 1;
        writeln('cell '+positionMarker.tostring+' filled');
        end;
    if (count > currentClueIndex)
      and (allowedClues[count].colour = allowedClues[count-1].colour)
      then
        begin
        result.X:=result.X+1;
        positionMarker:=positionMarker + 1;
        writeln('next clue same colour - marker '+positionMarker.toString);
        end;
    end;
  positionMarker:=spaceEnd + 1;
  for count:= 0 to currentClueIndex do
    begin
    clueValue:=allowedClues[count].value;
    clueColour:=allowedClues[count].colour;
    positionMarker:=positionMarker - clueValue;
    result.Y:=result.Y-clueValue;
    writeln('position marker is '+positionMarker.tostring);
    while (positionMarker > spaceStart)
      and (gameCells[positionMarker - 1].fill = cfFill)
      and (gameCells[positionMarker - 1 ].colour = cluecolour) do
        begin
        positionMarker:=positionMarker-1;
        result.Y:=result.Y - 1;
        writeln('cell '+positionMarker.tostring+' filled');
        end;
    if (count < currentClueIndex)
      and (allowedClues[count].colour = allowedClues[count+1].colour)
      then
        begin
        result.Y:=result.Y-1;
        positionMarker:=positionMarker - 1;
        writeln('previous clue same colour - marker '+positionMarker.toString);
        end;
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
  for rowId:=0 to pred(gameState.gameGrid.size) do
    begin
    outputRow:='';
    for colId:= 0 to pred(gameState.gameGrid[rowId].size) do
      begin
      currentCell:=gameState.gameGrid[rowId][colId];
        case currentCell.fill of
        cfEmpty: outputRow:=outputRow + '_';
        cfFill: outputRow:= outputRow + 'F';
        cfCross: outputRow:=outputRow + '.';
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

    writeln('*** ForceSpaces method - experimental');
    changesOnCurrentLoop:=changesOnCurrentLoop + forceSpacesRows(solvedGameState);
    solvedGameState:=applyChanges(solvedGameState,fChanges);
    outputCurrentGameState(solvedGameState);
    writeln('End ForceSpaces ');

    writeln('end loop '+loopCounter.tostring+' ----------------');
    loopCounter:=loopCounter+1;
    until changesOnCurrentLoop = 0;
  result:=solvedGameState;
end;

//Some useful methods



end.

