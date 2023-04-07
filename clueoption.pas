unit clueOption;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}

interface

uses
  Classes, SysUtils,enums,graphics;

type
  
  { TClueOption }

  TClueOption = class(TInterfacedObject)
    private
      fColour:TColor;
      fFill: ECellFillMode;
      fClueIndex: integer;
    public
      constructor create(colour:TColor;fill_: ECellFillMode;clueIndex_:integer);
      property colour:TColor read fColour;
      property fill: ECellFillMode read fFill write fFill;
      property clueIndex: integer read fClueIndex;
  end;

  TClueOptionEntry = array of TClueOption;
  TClueOptionFrame = array of TClueOptionEntry;

  { TClueOptionFrameHelper }

  TClueOptionFrameHelper = type helper for TClueOptionFrame
  function size: integer;
  function push(element:TClueOptionEntry):integer;
  function indexOf(element:TClueOptionEntry):integer;
  function combine:TClueOptionEntry;
  end;

  { TClueOptionEntryHelper }

  TClueOptionEntryHelper = type helper for TClueOptionEntry
  function size: integer;
  function push(element:TClueOption):integer;
  function indexOf(element:TClueOption):integer;
  function delete(index:integer):TClueOption;
  function moveToStart(index:integer):boolean;
  end;

implementation

{ TClueOption }

constructor TClueOption.create(colour: TColor; fill_: ECellFillMode;
  clueIndex_: integer);
begin
  fColour:=colour;
  fFill:=fill_;
  fClueIndex:= clueIndex_;
end;

{ TClueOptionEntryHelper }

function TClueOptionEntryHelper.size: integer;
begin
  result:=length(self);
end;

function TClueOptionEntryHelper.push(element: TClueOption): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueOptionEntryHelper.indexOf(element: TClueOption): integer;
begin
  for Result := 0 to High(self) do
    if self[Result].clueIndex = element.clueIndex then
      Exit;
  Result := -1;
end;

function TClueOptionEntryHelper.delete(index: integer): TClueOption;
var
  i:integer;
begin
  if (index < 0 ) or (index >= self.size) then exit;
  result:=self[index];
  for i:=index to pred(pred(self.size)) do
    self[i]:=self[i+1];
  setLength(self,self.size - 1);
end;

function TClueOptionEntryHelper.moveToStart(index: integer): boolean;
var
  element:TClueOption;
begin
  result:=false;
  element:=self.delete(index);
  if not assigned(element) then exit;
  insert(element,self,0);
end;

{ TClueOptionFrameHelper }

function TClueOptionFrameHelper.size: integer;
begin
  result:=length(self);
end;

function TClueOptionFrameHelper.push(element: TClueOptionEntry): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueOptionFrameHelper.indexOf(element: TClueOptionEntry): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

function TClueOptionFrameHelper.combine: TClueOptionEntry;
var
  frameLength,entryId,elementId:integer;

begin
  result:=self[0];
  if self.size = 0 then Exit;
  frameLength:=self[0].size;

  for elementId:=0 to pred(frameLength) do
    begin
    for entryId:=0 to pred(self.size) do
      begin
      if (self[entryId][elementId].colour <> result[elementId].colour)
      or (self[entryId][elementId].fill <> result[elementId].fill)
      or (self[entryId][elementId].clueIndex <> result[elementId].clueIndex)
      then Result[elementId].fill:=cfEmpty;
      end;
    end;
end;

end.

