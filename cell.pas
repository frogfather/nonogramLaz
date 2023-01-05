unit cell;

{$mode objfpc}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,arrayUtils,graphics;
type
  { ECellFillMode }
  ECellFillMode = (cfEmpty,cfFill,cfCross,cfDot);

  { TCell }
  TCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fFill: ECellFillMode;
    fColour: TColor;
    fOnCellChanged:TNotifyEvent;
    protected
    function getCellFill:ECellFillMode;
    function getRow:integer;
    function getCol:integer;
    public
    constructor create(row, column: integer;
      cellChangedHandler:TNotifyEvent;
      cellFill: ECellFillMode=cfEmpty);
    procedure setCellFill(fillMode:ECellFillMode);
    property cellId: TGUID read fCellId;
    property row: integer read getRow;
    property col: integer read getCol;
    property fill: ECellFillMode read fFill;
    property colour:TColor read fColour;
  end;

  TCells = array of TCell;

  { TCellsArrayHelper }

  TCellsArrayHelper = type helper for TCells
  function size: integer;
  function push(element:TCell):integer;
  function indexOf(element:TCell):integer;
  end;

implementation

{ TCellsArrayHelper }

function TCellsArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TCellsArrayHelper.push(element: TCell): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TCellsArrayHelper.indexOf(element: TCell): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

function TCell.getCellFill: ECellFillMode;
begin
  result:=fFill;
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
  cellFill: ECellFillMode);
begin
  fOnCellChanged:=cellChangedHandler;
  createGUID(fCellId);
  fRow:=row;
  fColumn:=column;
  fFill:=cellFill;
  fColour:=clDefault;
end;

procedure TCell.setCellFill(fillMode: ECellFillMode);
begin
  fFill:=fillMode;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

end.

