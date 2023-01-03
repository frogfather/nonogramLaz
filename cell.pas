unit cell;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils;
type

  TProcHandler = procedure();
  
  { TCell }

  TCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fValue: integer;
    fOnCellChanged:TNotifyEvent;
    protected
    function getValue:integer;
    function getRow:integer;
    function getCol:integer;
    public
    constructor create(row, column: integer;
      cellChangedHandler:TNotifyEvent;
      value: integer=-1);
    procedure setValue(newValue:integer);
    property cellId: TGUID read fCellId;
    property row: integer read getRow;
    property col: integer read getCol;
    property value: integer read getValue;
  end;

  TCells = array of TCell;
  TGameArray = array of array of TCell;

implementation

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


{ TCell }
//For new game: cellId is a new GUID
constructor TCell.create(row, column: integer;
  cellChangedHandler:TNotifyEvent;
  value: integer=-1);
var
  index:integer;
begin
  fOnCellChanged:=cellChangedHandler;
  createGUID(fCellId);
  fRow:=row;
  fColumn:=column;
  fValue:=value;
end;

procedure TCell.setValue(newValue: integer);
begin
  fValue:=newValue;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

end.

