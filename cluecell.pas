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
  function clueSum:integer;
  function delete(clueIndex:integer):integer;
  function limits(allowedClues:TClueCells; availableSpace,index:integer):TPoint;
  function join(separator:String):string;
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

function TClueCellsArrayHelper.limits(allowedClues:TClueCells;availableSpace,index: integer): TPoint;
var
  count, currentClueIndex:integer;
begin
  //return a point where X is the point the specified cell ends if it's as far left as possible
  //and Y is where it starts if it's as far right as it can go.
  //The allowed clues should be in order because anything else would suggest some very faulty logic elsewhere

  //This needs

  //The clues are in reverse order because... reasons.
  result:=Tpoint.Create(0,availableSpace + 1);
  currentClueIndex:=allowedClues.indexOf(self[index]);
  if (currentClueIndex = -1) then exit;
  for count:= currentClueIndex to pred(allowedClues.size) do
    begin
    result.X:= result.X + allowedClues[count].value;
    if (count > (currentClueIndex))
      and (allowedClues[count].colour = allowedClues[count-1].colour)
      then result.X:=result.X+1;
    end;
  for count:=(currentClueIndex) downto 0 do
    begin
    result.Y:=result.Y-allowedClues[count].value;
    if (count < currentClueIndex)
      and (allowedClues[count].colour = allowedClues[count+1].colour)
      then result.Y:=result.Y-1;
    end;
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

