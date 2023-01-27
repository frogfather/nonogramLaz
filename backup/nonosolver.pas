unit nonosolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameStateChanges;
type
  TNonogramSolver = class(TInterfacedObject)
    private
    //what methods do we need here?
    //First check simple overlaps
    function overlapRow(rowId:integer):TGameStateChanges;
    function overlapColumn(columnId:integer):TGameStateChanges;

    public
  end;

implementation

end.

