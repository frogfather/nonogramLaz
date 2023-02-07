unit cluechangeddelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type
  
  { TClueChangedDelegate }

  TClueChangedDelegate = class(TInterfacedObject)
    private
    fIsRow:boolean;
    fClueRowIndex:integer;
    fClueIndex:integer;
    public
    constructor create(clueRowIndex,clueIndex:integer;isRow:boolean=true);
    property isRow:boolean read fIsrow;
  end;

implementation

{ TClueChangedDelegate }

constructor TClueChangedDelegate.create(clueRowIndex, clueIndex: integer;
  isRow: boolean);
begin
  fIsRow:=isRow;
  fClueRowIndex:=clueRowIndex;
  fClueIndex:=clueIndex;
end;

end.

