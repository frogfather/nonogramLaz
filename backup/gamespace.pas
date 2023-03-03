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
    public
    constructor create(start_,end_:integer);
    property startPos:integer read fStart;
    property endPos:integer read fEnd;
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

