unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameStateChanges;
type
  
  { TNonogramSolver }

  TNonogramSolver = class(TInterfacedObject)
    private
    //what methods do we need here?
    //First check simple overlaps
    function overlapRow(rowId:integer):TGameStateChanges;
    function overlapColumn(columnId:integer):TGameStateChanges;

    public
  end;

implementation

{ TNonogramSolver }

function TNonogramSolver.overlapRow(rowId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
end;

function TNonogramSolver.overlapColumn(columnId: integer): TGameStateChanges;
begin
  result:=TGameStateChanges.create;
end;

end.

