unit clueBlock;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils;
type
  
  { TSpaceClueBlock }

  TSpaceClueBlock = class(TInterfacedObject)
  private
    fClueId:Integer;
    fClueSize:integer;
    fSpaceLeft:integer;
    fSpaceRight:integer;
    function getBlockSize:integer;
  public
    property clueId:integer read fClueId ;
    property clueSize: integer read fClueSize;
    property spaceLeft: integer read fSpaceLeft write fSpaceLeft;
    property spaceRight: integer read fSpaceRight write fSpaceRight;
    property blockSize:integer read getBlockSize;
    constructor create(clueId_,clueSize_:integer);
  end;

  TClueBlocks = array of TSpaceClueBlock;

  { TClueBlocksHelper }

  TClueBlocksHelper = type helper for TClueBlocks
  function size: integer;
  function push(element:TSpaceClueBlock):integer;
  function indexOf(element:TSpaceClueBlock):integer;
  function totalBlockSize:integer;
  function delete(clueIndex_:integer):integer;
  end;

implementation

{ TClueBlocksHelper }

function TClueBlocksHelper.size: integer;
begin
  result:=length(self);
end;

function TClueBlocksHelper.push(element: TSpaceClueBlock): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueBlocksHelper.indexOf(element: TSpaceClueBlock): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

function TClueBlocksHelper.totalBlockSize: integer;
var
  index:integer;
begin
  result:=0;
  for index:=0 to pred(self.size) do
    result:= result+ self[index].blockSize;
end;

//This deletes a block that has the specified clueIndex
function TClueBlocksHelper.delete(clueIndex_: integer): integer;
var
  blockIndex,blockPosition:integer;
  blockFound,done:boolean;
begin
  //if the blockIndex is out of range do nothing
  if (clueIndex_ < 0) or (clueIndex_ > Pred(self.size)) then exit;
  //find the block with this clue id
  blockPosition:=0;
  blockFound:=false;
  done:=false;
    repeat
    blockFound:= (Self[blockPosition].clueId = clueIndex_);
    if not blockfound then blockPosition:= blockPosition + 1;
    done:= blockFound or (blockPosition >= Self.size);
    until done;

  if blockFound then
    begin
    for blockIndex:=blockPosition to pred(self.size) do
      begin
      if (blockPosition < pred(self.size))
        then self[blockIndex]:=self[blockIndex+1];
      end;
    setlength(self,self.size - 1);
    end;

  result:=self.size;
end;

{ TSpaceClueBlock }

function TSpaceClueBlock.getBlockSize: integer;
begin
  result:=fClueSize+fSpaceLeft+fSpaceRight;
end;

constructor TSpaceClueBlock.create(clueId_, clueSize_:integer);
begin
  fClueId:=clueId;
  fClueSize:=clueSize;
  fSpaceLeft:=0;
  fSpaceRight:=0;
end;

end.

