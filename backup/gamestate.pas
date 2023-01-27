unit gameState;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameBlock,clueCell,gameStateChanges,gameStateChange,enums;

type 

{ TGameState }

 TGameState = class(TInterfacedObject)
private
  fGameBlock: TGameBlock;
  fRowClues: TClueBlock;
  fColumnClues:TClueBlock;
public
  property gameBlock:TGameBlock read fGameBlock;
  property rowClues: TClueBlock read fRowClues;
  property columnClues: TClueBlock read fColumnClues;
  constructor create(gameBlock_:TGameBlock;rowClues_,columnClues_:TClueBlock);
end;

implementation

{ TGameState }

constructor TGameState.create(gameBlock_: TGameBlock; rowClues_,
  columnClues_: TClueBlock);
begin
  fGameBlock:=gameBlock_;
  fRowClues:=rowClues_;
  fColumnClues:=columnClues_;
end;


end.

