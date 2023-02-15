unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,forms, SysUtils,arrayUtils,gameCell,gameBlock,gameState,
  gameStateChange,gameStateChanges,clueCell,graphics,clickDelegate,
  updateDelegate,cluechangeddelegate,gameModeChangedDelegate,clueclickeddelegate,
  enums,nonosolver,nonoDocHandler,iNonosolver;

const defaultDimensions: TPoint = (X:9; Y:9);
const gameVersion = 'nonogram-game-v1';
const defaultGameCellColour:TColor = $292929;

type
  { TNonogramGame }

  TNonogramGame = class(TinterfacedObject)
    private
    fHistory:TGameStateChangesList;
    fHistoryIndex:Integer;
    fName:string;
    fId:TGUID;
    fVersion:string;
    fDimensions:TPoint;
    fColours:TColours;
    //Originally intended to be immutable but now using GameStateChange objects
    fGameState: TGameState;
    //Initially the same as fGameState. Used for autosolving the game
    fInitialGameState: TGameState;
    //The result of the solving operation
    fSolvedGameState: TGameState;
    fSolver:INonogramSolver;
    fSelectedCell: TGameCell;
    fStarted:boolean;
    fSelectedRowClueSet:integer;
    fSelectedRowClueIndex:integer;
    fSelectedColumnClueSet:integer;
    fSelectedColumnClueIndex:integer;
    fOnCellStateChanged:TNotifyEvent;
    fOnGameModeChanged:TNotifyEvent;
    fOnClueChanged:TNotifyEvent;
    fSelectedColour:TColor;
    fInputMode: EInputMode;
    fGameMode: EGameMode;
    function getGameBlock:TGameBlock;
    function getRowClues: TClueBlock;
    function getColumnClues: TClueBlock;
    function getSelectedClueCells:TClueCells;
    function getSelectedClueCell:TClueCell;
    procedure cellChangedHandler(sender:TObject);
    function addNewClueCell(clueSet:TClueCells):TClueCells;
    //adjusts the game state and updates the history
    procedure applyChanges(changes:TGameStateChanges; forward: boolean=true);
    property version: string read fVersion;
    public
    constructor create(
        name:string;
        gameDimensions:TPoint;
        colours:TColours=nil);
    constructor create(filename:String);
    procedure setCellChangedHandler(handler:TNotifyEvent);
    procedure setGameModeChangedHandler(handler:TNotifyEvent);
    procedure setClueChangedHandler(handler:TNotifyEvent);
    procedure gameInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameInputClickHandler(Sender:TObject);
    procedure clueInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure clueInputClickHandler(Sender:TObject);
    procedure modeSwitchKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure saveToFile(filename:string);
    procedure start;
    procedure reset;
    procedure solveGame;
    function getCell(row,column:integer):TGameCell;
    function getCell(position_:TPoint):TGameCell;
    property colours:TColours read fColours write fColours;
    property block:TGameBlock read getGameBlock;
    property rowClues:TClueBlock read getRowClues;
    property columnClues:TClueBlock read getColumnClues;
    property selectedCell:TGameCell read fSelectedCell write fSelectedCell;
    property name:string read fName;
    property started:boolean read fStarted;
    property dimensions:TPoint read fDimensions;
    property selectedColour:TColor read fSelectedColour;
    property inputMode: EInputMode read fInputMode;
    property gameMode: EGameMode read fGameMode;
    property selectedRowClueSet: integer read fSelectedRowClueSet;
    property selectedRowClueIndex:integer read fSelectedRowClueIndex;
    property selectedColumnClueSet:integer read fSelectedColumnClueSet;
    property selectedColumnClueIndex:integer read fSelectedColumnClueIndex;
    property solver:INonogramSolver read fSolver write fSolver;
  end;

implementation

{ TNonogramGame }

//Create empty game with specified dimensions
constructor TNonogramGame.create(name: string; gameDimensions: TPoint;colours:TColours);
var
  row,col:integer;
  newGameRow:TGameCells;
  newGameBlock:TGameBlock;
  newRowClues:TClueCells;
  newRowClueBlock:TClueBlock;
  newColumnClues:TClueCells;
  newColumnClueBlock:TClueBlock;
begin
  fGameMode:=gmSet;
  fName:=name;
  CreateGuid(fId);
  fVersion:=gameVersion;
  fDimensions:=gameDimensions;
  if colours = nil then colours:=TColours.create(defaultGameCellColour);
  if (colours.indexOf(defaultGameCellColour) > -1) then fSelectedColour:=defaultGameCellColour
    else fSelectedColour:=colours[0];

  newGameBlock:=TGameBlock.create;
  newRowClueBlock:=TClueBlock.create;
  newColumnClueBlock:=TClueBlock.create;

  for row:=0 to pred(gameDimensions.Y) do
    begin
    //add a single empty clue
    newRowClues:=TClueCells.create;
    newRowClues.push(TClueCell.create(row,-1,-1,newRowClues.size)); //initially 0
    newGameRow:=TGameCells.create;
    for col:=0 to pred(gameDimensions.X) do
      begin
      newGameRow.push(TGameCell.create(col,row));
      if (row = 0) then
        begin
        newColumnClues:=TClueCells.create;
        newColumnClues.push(TClueCell.create(-1,col,-1,newColumnClues.size));
        newColumnClueBlock.push(newColumnClues);
        end;
      end;
    newGameBlock.push(newGameRow);
    newRowClueBlock.push(newRowClues);
    end;
  fHistory:=TGameStateChangesList.create;
  fGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fInitialGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fSolvedGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fHistoryIndex:=-1;
  fSelectedCell:=nil;
  fSelectedRowClueSet:=-1;
  fSelectedRowClueIndex:=-1;
  fSelectedColumnClueSet:=-1;
  fSelectedColumnClueIndex:=-1;
end;

//Load from file. Start in gmSolve. Number cells are not editable
constructor TNonogramGame.create(filename: String);
var
  nonoDocHandler:TNonogramDocumentHandler;
  newGameBlock:TGameBlock;
  newRowClueBlock:TClueBlock;
  newColumnClueBlock:TClueBlock;
begin
  fGameMode:=gmSolve;
  nonoDocHandler:=TNonogramDocumentHandler.Create;
  nonoDocHandler.loadFromFile(filename);
  fHistory:=TGameStateChangesList.create;
  newGameBlock:=nonoDocHandler.gameBlock;
  newRowClueBlock:=nonoDocHandler.rowClueBlock;
  newColumnClueBlock:=nonoDocHandler.columnClueBlock;
  fGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fInitialGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fSolvedGameState:=TGameState.create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  fName:=nonoDocHandler.name;
  fId:=nonoDocHandler.id;
  fVersion:=nonoDocHandler.version;
  fDimensions:=nonoDocHandler.dimensions;
  fColours:=nonoDocHandler.colours;
  fSelectedColour:=nonoDocHandler.selectedColour;
  //fSolver:=TNonogramSolver.create(fInitialGameState);
  //fSolvedGameState:= fSolver.solve;
  fHistoryIndex:=-1;
  fSelectedCell:=nil;
  fSelectedRowClueSet:=-1;
  fSelectedRowClueIndex:=-1;
  fSelectedColumnClueSet:=-1;
  fSelectedColumnClueIndex:=-1;
end;

function TNonogramGame.getGameBlock: TGameBlock;
begin
  result:=fGameState.gameBlock;
end;

function TNonogramGame.getRowClues: TClueBlock;
begin
  result:=fGameState.rowClues;
end;

function TNonogramGame.getColumnClues: TClueBlock;
begin
  result:=fGameState.columnClues;
end;

function TNonogramGame.getSelectedClueCells: TClueCells;
begin
  if (fSelectedColumnClueSet > -1) and (fSelectedColumnClueSet < columnClues.size)
    then result:=columnClues[fSelectedColumnClueSet]
  else if (fSelectedRowClueSet > -1) and (fSelectedRowClueSet < rowClues.size)
    then result:=rowClues[fSelectedRowClueSet];
end;

function TNonogramGame.getSelectedClueCell: TClueCell;
begin
  if (fSelectedColumnClueSet > -1) and (fSelectedColumnClueIndex > -1)
  and (fSelectedColumnClueSet < columnClues.size)
  and (fSelectedColumnClueIndex < columnClues[fSelectedColumnClueSet].size)
    then result:=columnClues[fSelectedColumnClueSet][fSelectedColumnClueIndex]
  else if (fSelectedRowClueSet > -1)and(fSelectedRowClueIndex > -1)
  and (fSelectedRowClueSet < rowClues.size)
  and (fSelectedRowClueIndex < rowClues[fSelectedRowClueSet].size)
    then result:=rowClues[fSelectedRowClueSet][fSelectedRowClueIndex];
end;

procedure TNonogramGame.cellChangedHandler(sender: TObject);
begin
  //update delegate should be a list of TPoint
  if (fOnCellStateChanged = nil) then exit;
  if sender is TGameCell then with sender as TGameCell do
  fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(col,row)));
end;

function TNonogramGame.addNewClueCell(clueSet: TClueCells):TClueCells;
var
  index_:integer;
begin
  //add a new clue on the end of the array
  result:=TClueCells.create;
  result.push(TClueCell.create(fSelectedRowClueSet,fSelectedColumnClueSet,-1,result.size));
  if (fSelectedRowClueIndex > -1) then fSelectedRowClueIndex:=0
    else fSelectedColumnClueIndex:=0;
end;

procedure TNonogramGame.applyChanges(changes: TGameStateChanges;
  forward: boolean);
var
  index:integer;
  change:TGameStateChange;
begin
  //update the game object with the changes
  for index:=0 to pred(changes.size) do
    begin
    change:=changes[index];
    if (change.cellType = ctGame) then
      begin
      if forward then
         begin
         fGameState.gameBlock[change.row][change.column].fill:=change.cellFillMode;
         fGameState.gameBlock[change.row][change.column].colour:=change.colour;
         end else
         begin
         fGameState.gameBlock[change.row][change.column].fill:=change.oldCellFillMode;
         fGameState.gameBlock[change.row][change.column].colour:=change.oldColour;
         end;
      end; //todo: clues
    end;
end;

procedure TNonogramGame.setCellChangedHandler(handler: TNotifyEvent);
begin
  fOnCellStateChanged:=handler;
end;

procedure TNonogramGame.setGameModeChangedHandler(handler: TNotifyEvent);
begin
  fOnGameModeChanged:=handler;
end;

procedure TNonogramGame.setClueChangedHandler(handler: TNotifyEvent);
begin
  fOnClueChanged:=handler;
end;

procedure TNonogramGame.gameInputKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //Shouldn't use specific key mappings here - should send an object with info such as 'back' forward' etc
  case key of
    66://b = back
      begin
      if (fHistoryIndex > -1) then
        begin
        applyChanges(fHistory[fHistoryIndex],false);
        fHistoryIndex:=fHistoryIndex - 1;
        if Assigned(fOnCellStateChanged) then fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(0,0))); //change to list
        end;
      end;
    70: //f = forward
      begin
      if (fHistoryIndex < pred(fHistory.size)) then
        begin
        fHistoryIndex:=fHistoryIndex + 1;
        applyChanges(fHistory[fHistoryIndex]);
        if Assigned(fOnCellStateChanged) then fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(0,0))); //change to list
        end;
      end;
    83://s (set/solve toggle)
      begin
      if (fGameMode = gmSolve) then fGameMode:=gmSet else fGameMode:=gmSolve;
      if Assigned(fOnGameModeChanged) then fOnGameModeChanged(TGameModeChangedDelegate.Create(fGameMode));
      end;
  end;
end;

procedure TNonogramGame.gameInputClickHandler(Sender: TObject);
var
  index:integer;
  gameStateChanges:TGameStateChanges;
  testFill:ECellFillMode;
begin
  if sender is TClickDelegate then with sender as TClickDelegate do
    begin
    if (selectedCells.size = 0) then exit;
    gameStateChanges:=TGameStateChanges.create;
    for index:=0 to pred(selectedCells.size) do
      begin
      //Generate a stateChange object for each cell that's changed
      selectedCell:= getCell(selectedCells[index]);
      if selectedCell <> Nil then
        begin
        //Temporary for testing
        if (selectedCell.fill = cfFill) then testFill:=cfEmpty else testFill:=cfFill;
        gameStateChanges.push(TGameStateChange.create(ctGame,selectedCell.col,selectedCell.row,testFill,selectedCell.fill,fSelectedColour,selectedCell.colour));
        end;
      end;
    if (fHistoryIndex < pred(fHistory.size))
       then fHistory.deleteAfter(fHistoryIndex);
    fHistory.push(gameStateChanges);
    fHistoryIndex:=fHistoryIndex + 1;
    applyChanges(gameStateChanges);
    //apply the changes
    if Assigned(fOnCellStateChanged) then fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(0,0))); //change to list
    end;
end;

procedure TNonogramGame.clueInputKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  validKey:boolean;
  selectedClueCell:TClueCell;
  selectedClueCells:TClueCells;
  newValue:integer;
  isRow,resize:boolean;
begin
  if (fSelectedRowClueSet = -1) and (fSelectedColumnClueSet = -1) then exit;
  validKey:= (key=8) or (key=13) or ((key > 36)and(key < 41)) or ((key > 47)and(key < 58));
  isRow:=(fSelectedRowClueSet > -1);
  if isRow then
    begin
    selectedClueCells:=fGameState.rowClues[fSelectedRowClueSet];
    selectedClueCell:=selectedClueCells[fSelectedRowClueIndex]
    end else
    begin
    selectedClueCells:=fGameState.columnClues[fSelectedColumnClueSet];
    selectedClueCell:=selectedClueCells[fSelectedColumnClueIndex];
    end;
  if not (validKey and assigned(selectedClueCell) )then exit;
  resize:=false;

  case key of
    8:
      begin
      if (selectedClueCell.value <= 0) then exit;
      newValue:=selectedClueCell.value div 10;
      if newValue = 0 then newValue:= -1;
      selectedClueCell.value:=newValue;
      end;
  13:
     begin
     //enter
     if selectedClueCell.value <= 0 then exit;
     if (selectedClueCells.indexOf(selectedClueCell) = 0) then
       begin
       if isRow then fGameState.rowClues[fSelectedRowClueSet]:=addNewClueCell(selectedClueCells)
       else fGameState.columnClues[fSelectedColumnClueSet]:=addNewClueCell(selectedClueCells);
       resize:=true;
       end;
     end;
  37:
     begin
     //left arrow
     if (isRow and (rowClues[fSelectedRowClueSet].size > fSelectedRowClueIndex + 1))
       then fSelectedRowClueIndex:=fSelectedRowClueIndex+1
     else if ((isRow=false) and (fSelectedColumnClueSet > 0))
       then
         begin
         fSelectedColumnClueSet:=fSelectedColumnClueSet - 1;
         if (columnClues[fSelectedColumnClueSet].size < fSelectedColumnClueIndex + 1)
         then fSelectedColumnClueIndex:=columnClues[fSelectedColumnClueSet].size -1;
         end;
     end;
  38:
     begin
     //up arrow
     if (isRow and (fSelectedRowClueIndex > 0)) then
       begin
       fSelectedRowClueIndex:=fSelectedRowClueIndex - 1;
       if (rowClues[fSelectedRowClueSet].size < fSelectedRowClueIndex + 1)
       then fSelectedRowClueIndex:= rowClues[fSelectedRowClueSet].size - 1;
       end
     else if ((isRow=false)
       and (columnClues[fSelectedColumnClueSet].size > fSelectedColumnClueIndex + 1))
       then fSelectedColumnClueIndex:=fSelectedColumnClueIndex + 1;
     end;
  39:
     begin
     //right arrow
     if (isRow and (fSelectedRowClueIndex > 0))
       then fSelectedRowClueIndex:=fSelectedRowClueIndex - 1
     else if ((isRow=false) and (columnClues.size > fSelectedColumnClueSet +1))
       then
         begin
         fSelectedColumnClueSet:=fSelectedColumnClueSet + 1;
         if (columnClues[fSelectedColumnClueSet].size < fSelectedColumnClueIndex + 1)
           then fSelectedColumnClueIndex:= columnClues[fSelectedColumnClueSet].size - 1;
         end;
     end;
  40:
     begin
     //down arrow
     if (isRow and (rowClues.size > fSelectedRowClueSet + 1))
       then
         begin
         fSelectedRowClueSet:= fSelectedRowClueSet + 1;
         if (rowClues[fSelectedRowClueSet].size < fSelectedRowClueIndex + 1)
         then fSelectedRowClueIndex:=rowClues[fSelectedRowClueSet].size - 1;
         end
     else if ((isRow=false) and (fSelectedColumnClueIndex > 1))
       then fSelectedColumnClueIndex:=fSelectedColumnClueIndex - 1;
     end;
  end;
  if (key > 47) and (key < 58)
  then
    begin
    //regular numbers
    if (selectedClueCell.value = -1)
      then selectedClueCell.value:= (key - 48)
    else if (((selectedClueCell.value * 10)+ (key - 48)) <= dimensions.X)
      then selectedClueCell.value:= (selectedClueCell.value * 10)+(key - 48);
    end;
  //signal that clue needs repainted
  if assigned(fOnClueChanged) then fOnClueChanged(TClueChangedDelegate.create(fSelectedRowClueSet,fSelectedRowClueIndex,isRow,resize))
end;

procedure TNonogramGame.clueInputClickHandler(Sender: TObject);
var
  maxSize,maxIndex:integer;
begin
  if sender is TClueClickDelegate then with sender as TClueClickDelegate do
    begin
    if isRow then maxSize:= rowClues.size else maxSize:= columnClues.size;
    if (clueSetIndex < 0) or (clueSetIndex >= maxSize) then exit;
    if isRow then maxIndex:=rowClues[clueSetIndex].size
      else maxIndex:= columnClues[clueSetIndex].size;
    if (clueIndex < 0) or (clueIndex >= maxIndex) then exit;
    if isRow then
      begin
      fSelectedRowClueSet:=clueSetIndex;
      fSelectedRowClueIndex:=clueIndex;
      fSelectedColumnClueSet:=-1;
      fSelectedColumnClueIndex:=-1;
      end else
      begin
      fSelectedColumnClueSet:=clueSetIndex;
      fSelectedColumnClueIndex:=clueIndex;
      fSelectedRowClueSet:=-1;
      fSelectedRowClueIndex:=-1;
      end;
    if assigned(fOnClueChanged) then fOnClueChanged(TClueChangedDelegate.create(fSelectedRowClueSet,fSelectedRowClueIndex,isRow))
    end;
end;

procedure TNonogramGame.modeSwitchKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //Handles change from fill, cross, dot
  //Shouldn't be using fixed key values here - display should handle that
  if (shift <> [ssShift, ssAlt]) then exit;
  case key of
    78: fInputMode:= imFill;
    67: fInputMode:= imCross;
    69: fInputMode:= imDot;
  end;
end;

procedure TNonogramGame.saveToFile(filename: string);
var
  docHandler:TNonogramDocumentHandler;
begin
  docHandler:=TNonogramDocumentHandler.create(fGameState.gameBlock,fGamestate.rowClues,fGameState.columnClues);
  docHandler.version:=gameVersion;
  docHandler.dimensions:=fDimensions;
  docHandler.colours:=fColours;
  docHandler.saveToFile(filename,fName,fId);
end;

procedure TNonogramGame.start;
begin
  fStarted:=true;
end;

procedure TNonogramGame.reset;
begin
  fStarted:=false;
  //and clear the game play after a dire warning
end;

procedure TNonogramGame.solveGame;
begin
  if not assigned(fSolver) then exit;

  //for testing;
  fGameState:=fSolver.solve(fInitialGameState);
  //fSolvedGameState:=fSolver.solve(fInitialGameState);
end;

function TNonogramGame.getCell(row, column: integer): TGameCell;
begin
  result:=nil;
  if (row < 0)or(row > pred(dimensions.Y))
     or (column < 0) or (column > pred(dimensions.X)) then exit;
  result:=fGameState.gameBlock[row][column];
end;

function TNonogramGame.getCell(position_: TPoint): TGameCell;
begin
  result:=getCell(position_.Y,position_.X);
end;

end.

