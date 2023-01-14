unit gameStateChanges;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,gameStateChange;

type
  TGameStateChanges = array of TGameStateChange;
  TGameStateChangesList = array of TGameStateChanges;

  { TGameStateChangesHelper }

  TGameStateChangesHelper = type helper for TGameStateChanges
  function size: integer;
  function push(element:TGameStateChange):integer;
  function indexOf(element:TGameStateChange):integer;
  end;

  { TGameStateChangesListHelper }

  TGameStateChangesListHelper = type helper for TGameStateChangesList
  function size: integer;
  function push(element:TGameStateChanges):integer;
  function indexOf(element:TGameStateChanges):integer;
  end;

implementation

{ TGameStateChangesListHelper }

function TGameStateChangesListHelper.size: integer;
begin
  result:=length(self);
end;

function TGameStateChangesListHelper.push(element: TGameStateChanges): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TGameStateChangesListHelper.indexOf(element: TGameStateChanges
  ): integer;
begin
  for result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

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

