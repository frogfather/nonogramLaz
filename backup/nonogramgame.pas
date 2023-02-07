unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,forms, SysUtils,arrayUtils,gameCell,gameBlock,gameState,
  gameStateChange,gameStateChanges,clueCell,graphics,clickDelegate,
  updateDelegate,gameModeChangedDelegate,enums,nonosolver,nonoDocHandler;

const defaultDimensions: TPoint = (X:9; Y:9);
const gameVersion = 'nonogram-game-v1';

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
    fSolver:TNonogramSolver;
    fSelectedCell: TGameCell;
    fStarted:boolean;
    fOnCellStateChanged:TNotifyEvent;
    fOnGameModeChanged:TNotifyEvent;
    fSelectedColour:TColor;
    fInputMode: EInputMode;
    fGameMode: EGameMode;
    function getGameBlock:TGameBlock;
    function getRowClues: TClueBlock;
    function getColumnClues: TClueBlock;
    procedure cellChangedHandler(sender:TObject);
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
    procedure gameInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameInputClickHandler(Sender:TObject);
    procedure modeSwitchKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure saveToFile(filename:string);
    procedure start;
    procedure reset;
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
  //for testing
  nonoDocHandler:TNonogramDocumentHandler;
begin
  fGameMode:=gmSet;
  fName:=name;
  CreateGuid(fId);
  fVersion:=gameVersion;
  fDimensions:=gameDimensions;
  if colours = nil then colours:=TColours.create(clBlack);
  if (colours.indexOf(clBlack) > -1) then fSelectedColour:=clBlack
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
  fSolver:=TNonogramSolver.create(fInitialGameState);
  fSolvedGameState:= fSolver.solve;
  fHistoryIndex:=-1;
  fSelectedCell:=nil;

  //For testing
  nonoDocHandler:=TNonogramDocumentHandler.Create(newGameBlock,newRowClueBlock,newColumnClueBlock);
  nonoDocHandler.version:=fVersion;
  nonoDocHandler.colours:=fColours;
  nonoDocHandler.selectedColour:=fSelectedColour;
  nonoDocHandler.id:=fId;
  nonoDocHandler.name:=fName;
  nonoDocHandler.saveToFile('/Users/cloudsoft/Downloads/test.txt',fName,fId);
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

procedure TNonogramGame.cellChangedHandler(sender: TObject);
begin
  //update delegate should be a list of TPoint
  if (fOnCellStateChanged = nil) then exit;
  if sender is TGameCell then with sender as TGameCell do
  fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(col,row)));
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

procedure TNonogramGame.gameInputKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //could adapt this to set clues if in set mode and set cells/change history if in play mode
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

procedure TNonogramGame.modeSwitchKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //Handles change from fill, cross, dot
  //Might want to make the mapping configurable
  if (shift <> [ssShift, ssAlt]) then exit;
  case key of
    78: fInputMode:= imFill;
    67: fInputMode:= imCross;
    69: fInputMode:= imDot;
  end;
end;

procedure TNonogramGame.saveToFile(filename: string);
begin
  //write to JSON or XML? Hmmm
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

