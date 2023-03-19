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
  function firstFilled(start_:integer=-1;end_:integer=-1):integer;
  function lastFilled(top_:integer=-1;bottom_:integer=-1):integer;
  function sequenceLength(start:integer):integer;
  function firstFree(start_:integer=-1):integer;
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

function TGameCellsArrayHelper.firstFilled(start_:integer;end_:integer): integer;
var
  index,startIndex,endIndex:integer;
begin
  result:=-1;
  if start_=-1 then startIndex:=0 else startIndex:=start_;
  if end_= -1 then endIndex:=pred(self.size)else endIndex:=end_;
  if (startIndex > pred(self.size))or(startIndex < 0)
  or (endIndex > pred(self.size)) or (endIndex < 0)
  or (endIndex < startIndex) then exit;
  for index:= startIndex to pred(Self.size) do
    if self[index].fill = cfFill then
      begin
        result:=index;
        exit;
      end;
end;

function TGameCellsArrayHelper.lastFilled(top_:integer;bottom_:integer): integer;
var
  index,topLimit,bottomLimit:integer;
begin
  result:=-1;
  if top_=-1 then topLimit:=pred(self.size) else topLimit:=top_;
  if bottom_= -1 then bottomLimit:= 0 else bottomLimit:= bottom_;
  if (topLimit > pred(self.size))or(topLimit < 0)
  or (bottomLimit > pred(self.size)) or (bottomLimit < 0)
  or (bottomLimit > topLimit) then exit;
  for index:= topLimit downto bottomLimit do
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

function TGameCellsArrayHelper.firstFree(start_: integer): integer;
var
  index:integer;
begin
  result:=-1;
  if (start_ < 0) or (start_ > pred(self.size)) then exit;
  for index:= start_ to pred(self.size) do
    if (self[index].fill = cfEmpty) then
      begin
      result:=index;
      exit;
      end;
end;

end.

