unit gameBlock;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameCell;

type
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

end.

