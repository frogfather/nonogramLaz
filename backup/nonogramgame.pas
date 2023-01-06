unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils,gameCell,clueCell,graphics,clickDelegate,updateDelegate;

const defaultDimensions: TPoint = (X:9; Y:9);
const gameVersion: string = '0.0.2';

type
  { EInputMode }
  EInputMode = (imFill, imCross, imDot);
  { EGameMode }
  EGameMode = (gmSet, gmSolve);
  { TNonogramGame }

  TNonogramGame = class(TinterfacedObject)
    private
    fName:string;
    fVersion:string;
    fDimensions:TPoint;
    fGameBlock: TGameBlock;
    fRowClues: TClueBlock;
    fColumnClues:TClueBlock;
    fSelectedCell: TGameCell;
    fStarted:boolean;
    fOnCellStateChanged:TNotifyEvent;
    fSelectedColour:TColor;
    fInputMode: EInputMode;
    fGameMode: EGameMode;
    procedure cellChangedHandler(sender:TObject);
    property version: string read fVersion;
    public
    constructor create(
        name:string;
        gameDimensions:TPoint);
    constructor create(filename:String);
    procedure setCellChangedHandler(handler:TNotifyEvent);
    procedure gameInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameInputClickHandler(Sender:TObject);
    procedure modeSwitchKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure saveToFile(filename:string);
    procedure start;
    procedure reset;
    function getCell(row,column:integer):TGameCell;
    function getCell(position_:TPoint):TGameCell;
    property block:TGameBlock read fGameBlock;
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

//Start in gmSet. Create empty cells according to the dimensions
//Create number cells that are editable
constructor TNonogramGame.create(name: string; gameDimensions: TPoint);
var
  row,col:integer;
  currentRow:TGameCells;
  currentClues:TClueCells;
begin
  fGameBlock:=TGameBlock.create;
  fRowClues:=TClueBlock.create;
  fColumnClues:=TClueBlock.create;
  fGameMode:=gmSet;
  fName:=name;
  fVersion:=gameVersion;
  fDimensions:=gameDimensions;
  fSelectedColour:=clBlack;
  for row:=0 to pred(gameDimensions.Y) do
    begin
    //add a single empty clue
    currentClues:=TClueCells.create;
    currentClues.push(TClueCell.create(row,-1,-1,currentClues.size));
    fRowClues.push(currentClues);
    currentRow:=TGameCells.create;
    for col:=0 to pred(gameDimensions.X) do
      begin
      currentRow.push(TGameCell.create(row,col,@cellChangedHandler));
      if (row = 0) then
        begin
        currentClues:=TClueCells.create;
        currentClues.push(TClueCell.create(-1,col,-1,currentClues.size));
        fColumnClues.push(currentClues);
        end;
      end;
    fGameBlock.push(currentRow);
    end;
  fSelectedCell:=nil;
end;

//Load from file. Start in gmSolve. Number cells are not editable
constructor TNonogramGame.create(filename: String);
begin
  fGameMode:=gmSolve;
  //loadfrom file
end;

procedure TNonogramGame.cellChangedHandler(sender: TObject);
begin
  if (fOnCellStateChanged = nil) then exit;
  if sender is TGameCell then with sender as TGameCell do
    fOnCellStateChanged(TUpdateDelegate.create(TPoint.Create(col,row)));
end;

procedure TNonogramGame.setCellChangedHandler(handler: TNotifyEvent);
begin
  fOnCellStateChanged:=handler;
end;

procedure TNonogramGame.gameInputKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //mostly clicks for this game but let's allow keyboard input too
end;

procedure TNonogramGame.gameInputClickHandler(Sender: TObject);
begin
  if sender is TClickDelegate then with sender as TClickDelegate do
    selectedCell:= getCell(position);
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
  result:=fGameBlock[row][column];
end;

function TNonogramGame.getCell(position_: TPoint): TGameCell;
begin
  result:=getCell(position_.X,position_.Y);
end;

end.

