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
    fResize:boolean;
    public
    constructor create(clueRowIndex,clueIndex:integer;isRow:boolean=true;resize:boolean=false);
    property isRow:boolean read fIsrow;
    property resize:boolean read fResize;
  end;

implementation

{ TClueChangedDelegate }

constructor TClueChangedDelegate.create(clueRowIndex, clueIndex: integer;
  isRow: boolean;resize:boolean);
begin
  fIsRow:=isRow;
  fClueRowIndex:=clueRowIndex;
  fClueIndex:=clueIndex;
  fResize:=resize;
end;

end.

