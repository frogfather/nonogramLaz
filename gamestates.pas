unit gameStates;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameState;
type
  TGameStates = array of TGameState;

  { TGameStatesHelper }

  TGameStatesHelper = type helper for TGameStates
    function size: integer;
    function push(element:TGameState):integer;
    function deleteAfter(index:Integer):integer;
    function indexOf(element:TGameState):integer;
    end;

implementation

{ TGameStatesHelper }

function TGameStatesHelper.size: integer;
begin
  result:=length(self);
end;

function TGameStatesHelper.push(element: TGameState): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

//never deletes first item as this is the original game state
function TGameStatesHelper.deleteAfter(index: Integer): integer;
begin
  if (index < 0) or (index >= self.size) then exit;
  setLength(self,index+1);
  result:=self.size;
end;

function TGameStatesHelper.indexOf(element: TGameState): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

end.

