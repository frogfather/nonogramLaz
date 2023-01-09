unit gameStateChanges;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameStateChange;

type
  TGameStateChanges = array of TGameStateChange;

  { TGameStateChangesHelper }

  TGameStateChangesHelper = type helper for TGameStateChanges
  function size: integer;
  function push(element:integer):integer;
  function indexOf(element:integer):integer;
  end;

implementation

{ TGameStateChangesHelper }

function TGameStateChangesHelper.size: integer;
begin
  result:=length(self);
end;

function TGameStateChangesHelper.push(element: TGameStateChange): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TGameStateChangesHelper.indexOf(element: TGameStateChange): integer;
begin
  for result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

end.

