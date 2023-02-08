unit clueCell;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,graphics;
type
  
  { TClueCell }

  TClueCell = class(TInterfacedObject)
  private
    fRow:integer;
    fColumn:integer;
    fIndex:integer;
    fValue:integer;
    fColour: TColor;
    fSolved:boolean;
  public
    constructor create(row_,column_,value_,index_:integer;colour_:TColor=clBlack);
    property row:integer read fRow;
    property column: integer read fColumn;
    property index: integer read fIndex write fIndex;
    property value: integer read fValue write fValue; //should handle size here
    property colour: TColor read fColour;
    property solved: boolean read fSolved write fSolved;
  end;

  TClueCells = array of TClueCell; //a single row of clues relating to a row or column
  TClueBlock = array of TClueCells; //a block of clues for all rows or columns

  { TClueCellsArrayHelper }

  TClueCellsArrayHelper = type helper for TClueCells
  function size: integer;
  function push(element:TClueCell):integer;
  function indexOf(element:TClueCell):integer;
  end;

  { TClueBlockArrayHelper }
  TClueBlockArrayHelper = type helper for TClueBlock
  function size: integer;
  function push(element:TClueCells):integer;
  function maxClues:integer;
  end;
implementation

{ TClueCellsArrayHelper }

function TClueCellsArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TClueCellsArrayHelper.push(element: TClueCell): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueCellsArrayHelper.indexOf(element: TClueCell): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

{ TClueBlockArrayHelper }

function TClueBlockArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TClueBlockArrayHelper.push(element: TClueCells): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueBlockArrayHelper.maxClues: integer;
var
  index:integer;
begin
  result:=0;
  //return the length of the longest TClueCells in this array
  if self.size = 0 then exit;
  for index:=0 to pred(self.size) do
    if self[index].size > result then result:= self[index].size;
end;

{ TClueCell }

constructor TClueCell.create(row_, column_, value_, index_: integer; colour_: TColor
  );
begin
  fRow:=row_;
  fColumn:=column_;
  fValue:=value_;
  fIndex:= index_;
  fColour:= colour_;
  fSolved:=false;
end;

end.

