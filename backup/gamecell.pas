unit gameCell;

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils,arrayUtils,graphics,enums,clue;
type

  { TGameCell }
  TGameCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fRowCandidates: TClueCells;//which row clues can this cell be?
    fColCandidates: TClueCells;
    fFill: ECellFillMode;
    fColour: TColor;
    public
    constructor create(column,row: integer;
      cellFill: ECellFillMode=cfEmpty);
    constructor create(column,row:integer; cellId:TGuid;
      cellColour:TColor;cellFill: ECellFillMode=cfEmpty);
    property cellId: TGUID read fCellId;
    property row: integer read fRow;
    property col: integer read fColumn;
    property fill: ECellFillMode read fFill write fFill;
    property colour:TColor read fColour write fColour;
    property rowCandidates:TClueCells read fRowCandidates write fRowCandidates;
    property colCandidates:TClueCells read fColCandidates write fColCandidates;
  end;

implementation

{ TGameCell }
constructor TGameCell.create(column,row: integer;
  cellFill: ECellFillMode);
begin
  createGUID(fCellId);
  fRow:=row;
  fColumn:=column;
  fFill:=cellFill;
  fColour:=clDefault;
end;

//used for copying existing cell
constructor TGameCell.create(column, row: integer; cellId: TGuid;
  cellColour:TColor;cellFill: ECellFillMode);
begin
  fRow:=row;
  fColumn:=column;
  fFill:=cellFill;
  fColour:=cellColour;
  fCellId:=cellId;
end;

end.

