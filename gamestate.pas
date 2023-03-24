unit gameState;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gamegrid,clueCell;

type 

{ TGameState }

 TGameState = class(TInterfacedObject)
private
  fGameGrid: TGameGrid;
  fRowClues: TClueBlock;
  fColumnClues:TClueBlock;
public
  property gameGrid:TGameGrid read fGameGrid;
  property rowClues: TClueBlock read fRowClues;
  property columnClues: TClueBlock read fColumnClues;
  constructor create(gameGrid_:TGameGrid;rowClues_,columnClues_:TClueBlock);
end;

implementation

{ TGameState }

constructor TGameState.create(gameGrid_: TGameGrid; rowClues_,
  columnClues_: TClueBlock);
begin
  fGameGrid:=gameGrid_;
  fRowClues:=rowClues_;
  fColumnClues:=columnClues_;
end;


end.

