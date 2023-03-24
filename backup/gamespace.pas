unit gameSpace;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,clueCell;

type
  
  { TGameSpace }

  TGameSpace = class(TInterfacedObject)
    private
    fStart:integer;
    fEnd:integer;
    fCandidates:TClueCells;
    function getSpaceSize:integer;
    public
    constructor create(start_,end_:integer);
    function clueWillFit(clueCell:TClueCell;left:boolean=true):boolean;
    property startPos:integer read fStart;
    property endPos:integer read fEnd;
    property spaceSize: integer read getSpaceSize;
    property candidates:TClueCells read fCandidates write fCandidates;
  end;

 TGameSpaces = array of TGameSpace;
 
 { TGameSpacesHelper }

 TGameSpacesHelper = type helper for TGameSpaces
  function size: integer;
  function push(element:TGameSpace):integer;
  function indexOf(element:TGameSpace):integer;
 end;

implementation

{ TGameSpace }
//The size of the space
function TGameSpace.getSpaceSize: integer;
begin
  result:= 1 + self.endPos - self.startPos;
end;

function TGameSpace.clueWillFit(clueCell: TClueCell;left:boolean): boolean;
var
  clueId,clueSizeTotal:integer;
begin
  clueSizeTotal:=0;
  for clueId:=0 to pred(self.candidates.size) do
    begin
    clueSizeTotal:=clueSizeTotal + self.candidates[clueId].value;
    if (clueId < pred(self.candidates.size))
    and (Self.candidates[clueId].colour = self.candidates[clueId+1].colour)
      then clueSizeTotal:=clueSizeTotal+1;
    end;
  //add the current clue to the total
  clueSizeTotal:=clueSizeTotal+clueCell.value;
  if (Self.candidates.size > 0)
  and ((left = true) and (clueCell.colour = self.candidates[0].colour))
  or ((left = false) and (clueCell.colour = self.candidates[pred(self.candidates.size)].colour))
    then clueSizeTotal:=clueSizeTotal+1;
  result:=Self.spaceSize >= clueSizeTotal;
end;

constructor TGameSpace.create(start_, end_: integer);
begin
  fStart:=start_;
  fEnd:=end_;
  fCandidates:=TClueCells.create;
end;

{ TGameSpacesHelper }

function TGameSpacesHelper.size: integer;
begin
  result:=length(self);
end;

function TGameSpacesHelper.push(element: TGameSpace): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TGameSpacesHelper.indexOf(element: TGameSpace): integer;
begin
   for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

end.

