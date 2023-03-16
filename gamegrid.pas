unit gamegrid;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameCell,enums,graphics;

type
  TGameCells = array of TGameCell; //cells for a row
  TGameGrid = array of TGameCells; //cells for the game

  { TGameCellsArrayHelper }

  TGameCellsArrayHelper = type helper for TGameCells
  function size: integer;
  function push(element:TGameCell):integer;
  function indexOf(element:TGameCell):integer;
  function filledCells:integer;
  function firstFilled(start_:integer=-1):integer;
  function lastFilled(end_:integer=-1):integer;
  function sequenceLength(start:integer):integer;
  end;

  { TGameGridArrayHelper }
  TGameGridArrayHelper = type helper for TGameGrid
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

function TGameCellsArrayHelper.firstFilled(start_:integer): integer;
var
  index,startIndex:integer;
begin
  result:=-1;
  if start_=-1 then startIndex:=0 else startIndex:=start_;
  if (startIndex > pred(self.size))or(startIndex < 0)then exit;
  for index:= startIndex to pred(Self.size) do
    if self[index].fill = cfFill then
      begin
        result:=index;
        exit;
      end;
end;

function TGameCellsArrayHelper.lastFilled(end_:integer): integer;
var
  index,startIndex:integer;
begin
  result:=-1;
  if end_=-1 then startIndex:=pred(self.size) else startIndex:=end_;
  if (startIndex > pred(self.size))or(startIndex < 0)then exit;
  for index:= startIndex downto 0 do
    if self[index].fill = cfFill then
      begin
        result:=index;
        exit;
      end;
end;

function TGameCellsArrayHelper.sequenceLength(start: integer): integer;
var
  index:integer;
  endSeq:boolean;
  seqColour:TColor;
begin
  result:=0;
  if (start < 0) or (start > pred(self.size)) or (self[start].fill <> cfFill) then exit;
  index:=start;
  endSeq:=false;
  seqColour:=self[start].colour;
  while not endSeq do
    begin
    if (index < pred(self.size))and(Self[index].fill = cfFill) and (self[index].colour = seqColour)
    then
      begin
      result:= result + 1;
      index:=index+1;
      end
    else endSeq:=true;
    end;
end;

end.
