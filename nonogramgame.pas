unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils,cell,graphics,clickDelegate;

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
    fCells: TCells;
    fSelectedCell: TCell;
    fStarted:boolean;
    fOnCellStateChanged:TNotifyEvent;
    fSelectedColour:TColor;
    fInputMode: EInputMode;
    fGameMode: EGameMode;
    procedure setCells(cells: TCells; candidates:TIntArray);
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
    function getCell(row,column:integer):TCell;
    function getCell(position_:TPoint):TCell;
    property cells:TCells read fCells;
    property selectedCell:TCell read fSelectedCell write fSelectedCell;
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
begin
  fCells:=TCells.create;
  fGameMode:=gmSet;
  fName:=name;
  fVersion:=gameVersion;
  fDimensions:=gameDimensions;
  fSelectedColour:=clBlack;
  for col:=0 to pred(gameDimensions.Y) do
    for row:=0 to pred(gameDimensions.X) do
    //create a cell
    begin
    fCells.push(TCell.create(row,col,@cellChangedHandler));
    end;
  fSelectedCell:=nil;
end;

//Load from file. Start in gmSolve. Number cells are not editable
constructor TNonogramGame.create(filename: String);
begin
  fGameMode:=gmSolve;
  //loadfrom file
end;

procedure TNonogramGame.setCells(cells: TCells; candidates: TIntArray);
begin

end;

procedure TNonogramGame.cellChangedHandler(sender: TObject);
begin
  if (fOnCellStateChanged <> nil) then
    fOnCellStateChanged(sender);//Sending the cell rather than the game
end;

procedure TNonogramGame.setCellChangedHandler(handler: TNotifyEvent);
begin
  fOnCellStateChanged:=handler;
end;

procedure TNonogramGame.gameInputKeyPressHandler(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //should use clicks
end;

procedure TNonogramGame.gameInputClickHandler(Sender: TObject);
begin
  //Indicates that the cell has been clicked
  //We need to have a type to pass click information
  //that is not associated with the display
  //needs info on which cell was clicked
  if sender is TClickDelegate then with sender as TClickDelegate do
    begin
    selectedCell:= getCell(position);
    writeln('selected cell now '+selectedCell.col.ToString+' '+selectedCell.row.ToString);
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

function TNonogramGame.getCell(row, column: integer): TCell;
begin
  result:=fCells[column+(row * fDimensions.X)];
end;

function TNonogramGame.getCell(position_: TPoint): TCell;
begin
  result:=getCell(position_.X,position_.Y);
end;

end.

