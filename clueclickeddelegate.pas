unit clueclickeddelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type
  
  { TClueClickDelegate }

  TClueClickDelegate = Class(TInterfacedObject)
    private
    fIsrow: boolean;
    fClueSetIndex:integer;
    fClueIndex:integer;
    public
    constructor create(clueSetIndex,clueIndex:integer;isRow:boolean=true);
    property isRow:boolean read fIsRow;
    property clueSetIndex:integer read fClueSetIndex;
    property clueIndex:integer read fClueIndex;
  end;

implementation

{ TClueClickDelegate }

constructor TClueClickDelegate.create(clueSetIndex, clueIndex: integer;
  isRow: boolean);
begin
  fIsRow:=isRow;
  fClueSetIndex:=clueSetIndex;
  fClueIndex:=clueIndex;
end;

end.

