unit clueCell;

{$mode ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils,graphics;
type
  
  { TClueCell }

  TClueCell = class(TInterfacedObject)
  private
    fRow:integer;
    fColumn:integer;
    fIndex:integer;
    fValue:integer;
    fColour: TColor;
  public
    constructor create(row_,column_,value_,index_:integer;colour_:TColor=clBlack);
    property row:integer read fRow;
    property column: integer read fColumn;
    property index:integer read fIndex;
    property value: integer read fValue;
    property colour: TColor read fColour;
  end;

  TClueCells = array of TClueCell; //a single row of clues relating to a row or column
  TClueBlock = array of TClueCells; //a block of clues for all rows or columns
implementation

{ TClueCell }

constructor TClueCell.create(row_, column_, value_, index_: integer; colour_: TColor
  );
begin
  fRow:=row_;
  fColumn:=column_;
  fValue:=value_;
  fIndex:= index_;
  fColour:= colour_;
end;

end.

