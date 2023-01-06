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
    fCandidates: TIntArray;//which clues can this cell be?
    fFill: ECellFillMode;
    fColour: TColor;
    public
    constructor create(row, column: integer;
      cellFill: ECellFillMode=cfEmpty);
    property cellId: TGUID read fCellId;
    property row: integer read fRow;
    property col: integer read fColumn;
    property fill: ECellFillMode read fFill;
    property colour:TColor read fColour;
    property candidates:TIntArray read fCandidates;
  end;
  TGameCells = array of TGameCell; //cells for a row
  TGameBlock = array of TGameCells; //cells for the game

  { TGameCellsArrayHelper }

  TGameCellsArrayHelper = type helper for TGameCells
  function size: integer;
  function push(element:TGameCell):integer;
  function indexOf(element:TGameCell):integer;
  end;

  { TGameBlockArrayHelper }
  TGameBlockArrayHelper = type helper for TGameBlock
  function size: integer;
  function push(element:TGameCells):integer;
  end;

implementation

{ TGameBlockArrayHelper }

function TGameBlockArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TGameBlockArrayHelper.push(element: TGameCells): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

{ TGameCellsArrayHelper }

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
constructor TGameCell.create(row, column: integer;
  cellFill: ECellFillMode);
begin
  createGUID(fCellId);
  fRow:=row;
  fColumn:=column;
  fFill:=cellFill;
  fColour:=clDefault;
end;

end.

