unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils,cell;

const defaultDimensions: TPoint = (X:9; Y:9);
const gameVersion: string = '0.0.2';

type
  { EGameMode }
  EInputMode = (imFill, imCross, imDot);
  EGameMode = (gmSet, gmSolve);
  { TNonogramGame }

  TNonogramGame = class(TinterfacedObject)
    private
    fName:string;
    fVersion:string;
    fDimensions:TPoint;
    fCells: TCells;
    fStarted:boolean;
    fOnCellStateChanged:TNotifyEvent;
    fInputMode: EInputMode;
    fGameMode: EGameMode;
    function findCell(row,col:integer):TCell;
    function readCellsFromFile(filename:string):TCells;
    procedure setCells(cells: TCells; candidates:TIntArray);
    procedure cellChangedHandler(sender:TObject);
    property version: string read fVersion;
    public
    constructor create(
        name:string;
        gameDimensions:TPoint;
        cells:TCells=nil);
    constructor create(filename:String);
    procedure setCellChangedHandler(handler:TNotifyEvent);
    procedure gameInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure modeSwitchKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure saveToFile(filename:string);
    procedure start;
    procedure reset;
    function getCell(row,column:integer):TCell;
    property cells:TCells read fCells;
    property name:string read fName;
    property started:boolean read fStarted;
    property dimensions:TPoint read fDimensions;
    property inputMode: EInputMode read fInputMode;
    property gameMode: EGameMode read fGameMode;
  end;

implementation

{ TNonogramGame }

constructor TNonogramGame.create(filename: string);
begin
  //loadfrom file
end;

end.

