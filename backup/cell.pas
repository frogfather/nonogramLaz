unit cell;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils,customcell;
type

  TProcHandler = procedure();
  { TSudokuNumber }
  TSudokuNumber = class(TInterfacedObject)
    private
    fValue:integer;
    fAvailable:boolean;
    fExclude:boolean;
    property exclude: boolean read fExclude write fExclude;
    public
    constructor create(aOwner:TObject;initValue:integer=-1);
    property value: integer read fValue;
    property available:boolean read fAvailable;
  end;

  TSudokuNumbers = array of TSudokuNumber;
  
  { TCell }

  TCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fBox: integer;
    fValue: integer;
    fEdgeMarks: TIntArray;
    fCentreMarks: TIntArray;
    fCandidates: TSudokuNumbers;
    fChangedCandidate: TSudokuNumber;
    fOnCellChanged:TNotifyEvent;
    protected
    function getValue:integer;
    function getRow:integer;
    function getCol:integer;
    function getBox:integer;
    function getEdgeMarks:TIntArray;
    function getCentreMarks:TIntArray;
    public
    constructor create(row, column, box: integer;
      cellChangedHandler:TNotifyEvent;
      candidates:TIntArray;
      edgeMarks: TIntArray=nil;
      centreMarks:TIntArray=nil;
      value: integer=-1);
    constructor create(row, column, box: integer;
      cellChangedHandler:TNotifyEvent;
      id:TGUID;
      candidates:TIntArray;
      edgeMarks: TIntArray=nil;
      centreMarks:TIntArray=nil;
      value: integer=-1);
    procedure setValue(newValue:integer);
    procedure updateEdgeMarks(var newValues:TIntArray);
    procedure updateCentreMarks(var newValues:TIntArray);
    property cellId: TGUID read fCellId;
    property row: integer read getRow;
    property col: integer read getCol;
    property box: integer read getBox;
    property value: integer read getValue;
    property centreMarks: TIntArray read fCentreMarks;
    property edgeMarks: TIntArray read fEdgeMarks;
    property candidates:TSudokuNumbers read fCandidates;
    property changedCandidate: TSudokuNumber read fChangedCandidate;
  end;

  TCells = array of TCell;
  TGameArray = array of array of TCell;

implementation

{ TSudokuNumber }


constructor TSudokuNumber.create(aOwner:TObject;initValue: integer);
begin
  fValue:= initValue;
  fAvailable:= true;
  fExclude:= false;
end;

function TCell.getValue: integer;
begin
  result:=fValue;
end;

function TCell.getRow: integer;
begin
  result:=fRow;
end;

function TCell.getCol: integer;
begin
  result:=fColumn;
end;

function TCell.getBox: integer;
begin
  result:=fBox;
end;

function TCell.getEdgeMarks: TIntArray;
begin
  result:=fEdgeMarks;
end;

function TCell.getCentreMarks: TIntArray;
begin
  result:=fCentreMarks;
end;

{ TCell }
//For new game: cellId is a new GUID
constructor TCell.create(row, column, box: integer;
  cellChangedHandler:TNotifyEvent;
  candidates:TIntArray;
  edgeMarks: TIntArray=nil;
  centreMarks:TIntArray=nil;
  value: integer=-1);
var
  sudokuNos: TSudokuNumbers;
  index:integer;
begin
  fOnCellChanged:=cellChangedHandler;
  createGUID(fCellId);
  fRow:=row;
  fColumn:=column;
  fBox:=box;
  //convert candidates into SudokuNumbers
  sudokuNos:=TSudokuNumbers.create;
  setLength(sudokuNos,length(candidates));
  for index:=0 to pred(length(candidates)) do
    sudokuNos[index]:= TSudokuNumber.create(self,candidates[index]);
  fCandidates:=sudokuNos;
  fcentreMarks:= centreMarks;
  fEdgeMarks:= edgeMarks;
  fValue:=value;
end;

//For game loaded from file: cellId is from saved data
constructor TCell.create(row, column, box: integer;
  cellChangedHandler:TNotifyEvent;
  id: TGUID;
  candidates: TIntArray; edgeMarks: TIntArray; centreMarks: TIntArray;
  value: integer);
var
  sudokuNos: TSudokuNumbers;
  index:integer;
begin
  fOnCellChanged:=cellChangedHandler;
  fCellId:=id;
  fRow:=row;
  fColumn:=column;
  fBox:=box;
  //convert candidates into SudokuNumbers
  sudokuNos:=TSudokuNumbers.create;
  setLength(sudokuNos,length(candidates));
  for index:=0 to pred(length(candidates)) do
    sudokuNos[index]:= TSudokuNumber.create(self,candidates[index]);
  fCandidates:=sudokuNos;
  fcentreMarks:= centreMarks;
  fEdgeMarks:= edgeMarks;
  fValue:=value;
end;

procedure TCell.setValue(newValue: integer);
begin
  fValue:=newValue;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

procedure TCell.updateEdgeMarks(var newValues: TIntArray);
begin
  fEdgeMarks:=newValues;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

procedure TCell.updateCentreMarks(var newValues: TIntArray);
begin
  fCentreMarks:=newValues;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

end.

