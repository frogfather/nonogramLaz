unit clueBlock;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils;
type
  
  { TClueBlock }

  TClueBlock = class(TInterfacedObject)
  private
    fClueId:Integer;
    fClueSize:integer;
    fSpaceLeft:integer;
    fSpaceRight:integer;
    function getBlockSize:integer;
  public
    property clueId:integer read fClueId write fClueId;
    property clueSize: integer read fClueSize write fClueSize;
    property spaceLeft: integer read fSpaceLeft write fSpaceLeft;
    property spaceRight: integer read fSpaceRight write fSpaceRight;
    property blockSize:integer read getBlockSize;
  end;

  TClueBlocks = array of TClueBlock;

  { TClueBlocksHelper }

  TClueBlocksHelper = type helper for TClueBlocks
  function size: integer;
  function push(element:TClueBlock):integer;
  function indexOf(element:TClueBlock):integer;
  end;

implementation

{ TClueBlocksHelper }

function TClueBlocksHelper.size: integer;
begin
  result:=length(self);
end;

function TClueBlocksHelper.push(element: TClueBlock): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TClueBlocksHelper.indexOf(element: TClueBlock): integer;
begin
  for Result := 0 to High(self) do
    if self[Result] = element then
      Exit;
  Result := -1;
end;

{ TClueBlock }

function TClueBlock.getBlockSize: integer;
begin
  result:=fClueSize+fSpaceLeft+fSpaceRight;
end;

end.

