unit gameBlock;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameCell,enums,gameSpace;

type
  TGameCells = array of TGameCell; //cells for a row
  TGameBlock = array of TGameCells; //cells for the game

  { TGameCellsArrayHelper }

  TGameCellsArrayHelper = type helper for TGameCells
  function size: integer;
  function push(element:TGameCell):integer;
  function indexOf(element:TGameCell):integer;
  function filledCells:integer;
  function spaces:TGameSpaces;
  end;

  { TGameBlockArrayHelper }
  TGameBlockArrayHelper = type helper for TGameBlock
  function size: integer;
  function push(element:TGameCells):integer;
  function getColumn(columnId:integer):TGameCells;
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

function TGameBlockArrayHelper.getColumn(columnId: integer): TGameCells;
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

function TGameCellsArrayHelper.spaces: TGameSpaces;
var
  index:integer;
  startBlock,endBlock:integer;
begin
  result:=TGameSpaces.create;
  startBlock:=-1;
  endBlock:=-1;
  for index:=0 to self.size do
    begin
    if (index < self.size) and (self[index].fill <> cfCross) then
      begin
      if startBlock = -1 then
        begin
        startBlock:=index;
        endBlock:=index;
        end
      else endBlock:=endBlock + 1;
      end else if (endBlock > -1) then
      begin
      result.push(TGameSpace.Create(startBlock,endBlock));
      startBlock:=-1;
      endBlock:=-1;
      end;
    end;

  if (result.size > 0) then for index:=0 to pred(result.size) do
    begin
    writeln('space '+index.toString+' start '+result[index].startPos.toString+':'+result[index].endPos.ToString);
    end;

end;

end.

