unit gameBlock;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameCell,enums,gameSpace;

type
  TGameCells = array of TGameCell; //cells for a row
  TGameGrid = array of TGameCells; //cells for the game

  { TGameCellsArrayHelper }

  TGameCellsArrayHelper = type helper for TGameCells
  function size: integer;
  function push(element:TGameCell):integer;
  function indexOf(element:TGameCell):integer;
  function filledCells:integer;
  function firstFilled:integer;
  function lastFilled:integer;
  end;

  { TGameGridArrayHelper }
  TGameGridArrayHelper = type helper for TGameBlock
  function size: integer;
  function push(element:TGameCells):integer;
  function getColumn(columnId:integer):TGameCells;
  end;

implementation

{ TGameBlockArrayHelper }

function TGameGridArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TGameGridArrayHelper.push(element: TGameCells): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TGameGridArrayHelper.getColumn(columnId: integer): TGameCells;
var
  rowIndex:integer;
begin
  result:=TGameCells.create;
  for rowIndex:= 0 to pred(self.size) do
    result.push(self[rowIndex][columnId]);
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

function TGameCellsArrayHelper.filledCells: integer;
var
  index:integer;
begin
  result:=0;
  for index:=0 to pred(self.size) do
    if (self[index].fill = cfFill) then result:=result+1;
end;

function TGameCellsArrayHelper.firstFilled: integer;
var
  index:integer;
begin
  result:=-1;
  for index:=0 to pred(Self.size) do
    if self[index].fill = cfFill then
      begin
        result:=index;
        exit;
      end;
end;

function TGameCellsArrayHelper.lastFilled: integer;
var
  index:integer;
begin
  result:=-1;
  for index:= pred(Self.size) downto 0 do
    if self[index].fill = cfFill then
      begin
        result:=index;
        exit;
      end;
end;

end.

