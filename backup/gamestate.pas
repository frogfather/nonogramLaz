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
  constructor create(source: TGameState; changes: TGameStateChanges);
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

constructor TGameState.create(source: TGameState; changes: TGameStateChanges);
var
  index: integer;
  change:TGameStateChange;
begin
  //This, unsurprisingly doesn't work because they are reference types
  fGameBlock:=source.fGameBlock;
  fRowClues:=source.fRowClues;
  fColumnClues:=source.fColumnClues;
  for index:=0 to pred(changes.size) do
    begin
    //apply each change
    change:=changes[index];
    case change.cellType of
    ctGame:
      begin
      if (change.column < 0) or (change.column >= fGameBlock.size)then Exit; //should record an error at least
      //log change
      fGameBlock[change.row][change.column].fill:=change.cellFillMode;
      fGameBlock[change.row][change.column].colour:=change.colour;
      end;
    ctClue:
      begin
      //log change
      if (change.column > -1)
        then fColumnClues[change.column][index].solved:= change.solved
      else if (change.row > -1)
        then fRowClues[change.row][index].solved:=change.solved;
      end;
    end;
  end;
end;

end.

