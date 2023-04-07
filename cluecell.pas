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
  function insertAtPosition(element:TClueCell;position:integer):integer;
  function indexOf(element:TClueCell):integer;
  function clueSum:integer;
  function allElementsLengthLessThan(length:integer):boolean;
  function delete(clueIndex:integer):integer;
  function join(separator:String):string;
  function totalClueLength:integer;
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

function TClueCellsArrayHelper.insertAtPosition(element: TClueCell; position: integer
  ): integer;
begin
  if (position < 0) or (position > pred(self.size)) then
    push(element) else insert(element,self,position);
  result:=self.size;
end;

function TClueCellsArrayHelper.indexOf(element: TClueCell): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

//This returns the sum of the value of the clues, not how much space they
//take up on the grid
function TClueCellsArrayHelper.clueSum: integer;
var
  index:integer;
begin
  result:=0;
  if self.size = 0 then exit;
  for index:=0 to pred(self.size)do
    result:=result+self[index].value;
end;

function TClueCellsArrayHelper.allElementsLengthLessThan(length: integer
  ): boolean;
var
  index:integer;
begin
  result:=true;
  for index:= 0 to pred(self.size) do
    if self[index].value >= length then
      begin
      result:=false;
      exit;
      end;
end;

function TClueCellsArrayHelper.delete(clueIndex: integer): integer;
var
  index:integer;
begin
  //if the index is out of range do nothing
  if (clueIndex < 0) or (clueIndex > Pred(self.size)) then exit;
  for index:=clueIndex to pred(self.size) do
    begin
    if (clueIndex < pred(self.size))
      then self[clueIndex]:=self[clueIndex+1];
    end;
  setlength(self,self.size - 1);
  result:=self.size;
end;

function TClueCellsArrayHelper.join(separator: String): string;
var
  index:integer;
begin
  result:='';
  for index:= 0 to pred(self.size) do
    begin
    result:=result+Self[index].value.toString;
    if (index < pred(self.size))then result:=result+ separator;
    end;
end;

function TClueCellsArrayHelper.totalClueLength: integer;
var
  index:integer;
begin
  result:=0;
  for index:= pred(self.size) downto 0 do
    begin
    result:=Result+self[index].value;
    if (index > 0) and (self[index].colour = self[index -1].colour)
      then result:=result+1;
    end;
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

