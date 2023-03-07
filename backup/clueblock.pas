unit clueBlock;

{$mode ObjFPC}{$H+}

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

implementation

{ TClueBlock }

function TClueBlock.getBlockSize: integer;
begin
  result:=fClueSize+fSpaceLeft+fSpaceRight;
end;

end.

