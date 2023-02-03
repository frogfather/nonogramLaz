unit gameCell;

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils,arrayUtils,graphics,enums;
type

  { TGameCell }
  TGameCell = class(TInterfacedObject)
    private
    fCellId: TGUID;
    fRow: integer;
    fColumn: integer;
    fCandidates: TIntArray;//which clues can this cell be?
    fFill: ECellFillMode;
    fColour: TColor;
    public
    constructor create(column,row: integer;
      cellFill: ECellFillMode=cfEmpty);
    constructor create(column,row:integer; cellId:TGuid;
      cellFill: ECellFillMode=cfEmpty;cellColour:TColor=nil);
    property cellId: TGUID read fCellId;
    property row: integer read fRow;
    property col: integer read fColumn;
    property fill: ECellFillMode read fFill write fFill;
    property colour:TColor read fColour write fColour;
    property candidates:TIntArray read fCandidates;
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
  cellFill: ECellFillMode);
begin
  fRow:=row;
  fColumn:=column;
  fFill:=cellFill;
  fColour:=clDefault;
  fCellId:=cellId;
end;

end.

