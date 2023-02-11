unit gamestatechange;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,graphics,enums;
type
  { TGameStateChange }

  TGameStateChange = class(TInterfacedObject)
  private
  fCellType: ECellType;
  fColumn:integer;
  fRow: integer;
  fCellFillMode:ECellFillMode;
  fColour:TColor;
  fOldFillMode:ECellFillMode;
  fOldColour:TColor;
  fIndex:integer;
  fSolved:Boolean;
  public
  property cellType:ECellType read fCellType;
  property column:integer read fColumn;
  property row: integer read fRow;
  property cellFillMode:ECellFillMode read fCellFillMode;
  property colour: TColor read fColour;
  property oldCellFillMode: ECellFillMode read fOldFillMode;
  property oldColour:TColor read fOldColour;
  property index: integer read fIndex;
  property solved: boolean read fSolved;
  constructor create(cellType_:ECellType;column_,row_:integer;cellFillMode_,oldCellFillMode_:ECellFillMode;colour_,oldColour_:TColor);
  end;

implementation

{ TGameStateChange }

constructor TGameStateChange.create(cellType_: ECellType; column_,
  row_: integer; cellFillMode_, oldCellFillMode_: ECellFillMode; colour_,
  oldColour_: TColor);
begin
  fCellType:=cellType_;
  fColumn:=column_;
  fRow:=row_;
  fCellFillMode:=cellFillMode_;
  fOldFillMode:=oldCellFillMode_;
  fColour:=colour_;
  fOldColour:=oldColour_;
end;

end.

