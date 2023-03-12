unit gameSpace;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,clueCell,spaceclueblock;

type
  
  { TGameSpace }

  TGameSpace = class(TInterfacedObject)
    private
    fStart:integer;
    fEnd:integer;
    fCandidates:TClueCells;
    fSpaceClueBlocks:TSpaceClueBlocks;
    function getSpaceSize:integer;
    function getFreeSpace:integer;
    public
    constructor create(start_,end_:integer);
    property startPos:integer read fStart;
    property endPos:integer read fEnd;
    property spaceSize: integer read getSpaceSize;
    property candidates:TClueCells read fCandidates write fCandidates;
    property spaceClueBlocks:TSpaceClueBlocks read fSpaceClueBlocks write fSpaceClueBlocks;
    property freeSpace: integer read getFreeSpace;
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

//The free space once any blocks are counted
function TGameSpace.getFreeSpace: integer;
begin
  result:=self.spaceSize - spaceClueBlocks.totalBlockSize;
end;

constructor TGameSpace.create(start_, end_: integer);
begin
  fStart:=start_;
  fEnd:=end_;
  fCandidates:=TClueCells.create;
  fSpaceClueBlocks:=TSpaceClueBlocks.create;
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

