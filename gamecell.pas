unit gameCell;

{$mode objfpc}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,arrayUtils,graphics;
type
  { ECellFillMode }
  ECellFillMode = (cfEmpty,cfFill,cfCross,cfDot);

  { TGameCell }
  TGameCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fBlocks: TIntArray;
    fFill: ECellFillMode;
    fColour: TColor;
    fOnCellChanged:TNotifyEvent;
    public
    constructor create(row, column: integer;
      cellChangedHandler:TNotifyEvent;
      cellFill: ECellFillMode=cfEmpty);
    procedure setCellFill(fillMode:ECellFillMode);
    property cellId: TGUID read fCellId;
    property row: integer read fRow;
    property col: integer read fColumn;
    property fill: ECellFillMode read fFill;
    property colour:TColor read fColour;
  end;
  TGameCells = array of TGameCell;

   { TGameCellsArrayHelper }

  TGameCellsArrayHelper = type helper for TGameCells
  function size: integer;
  function push(element:TGameCell):integer;
  function indexOf(element:TGameCell):integer;
  end;

implementation

{ TCellsArrayHelper }

function TGameCellsArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TGameCellsArrayHelper.push(element: TGameCell): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TGameCellsArrayHelper.indexOf(element: TGameCell): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

{ TGameCell }
//For new game: cellId is a new GUID
constructor TGameCell.create(row, column: integer;
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

procedure TGameCell.setCellFill(fillMode: ECellFillMode);
begin
  fFill:=fillMode;
  if (fOnCellChanged <> nil) then
    fOnCellChanged(self);
end;

end.

