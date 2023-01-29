unit nonoDocHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,xml_doc_handler,gameBlock,gameCell,clueCell;
type
  
  { TNonogramDocumentHandler }

  TNonogramDocumentHandler = class(TXMLDocumentHandler)
    private
    fGameBlock:TGameBlock;
    fRowClueBlock:TClueBlock;
    fColumnClueBlock:TClueBlock;

    procedure addGameCells(cells:TGameCells;rowNo:integer);
    procedure addGameCell(cell:TGameCell;colNo:integer);
    procedure addRowClues(clues:TClueCells;rowNo:integer);
    procedure addRowClue(clue:TClueCell;clueIndex:integer);
    procedure addColumnClues(clues:TClueCells;colNo:integer);
    procedure addColumnClue(clue:TClueCell;clueIndex:integer);
    public
    property gameBlock:TGameBlock read fGameBlock write fGameBlock;
    property rowClueBlock:TClueBlock read fRowClueBlock write fRowClueBlock;
    property columnClueBlock:TClueBlock read fColumnClueBlock write fColumnClueBlock;
    procedure saveToFile(filename,gameName:string;gameId:TGuid);
    procedure loadFromFile(filename:string);
  end;


implementation

{ TNonogramDocumentHandler }
//XML structure
//<root>
//<gameBlock> represents the game
//<gameCells> represents a row of the game
//<gameCell > represents an element of the game
//<id>
//<row>
//<column>
//<candidates>
//<candidate>
//<fillMode>
//<colour>
//</gameCell>

//Public methods
procedure TNonogramDocumentHandler.saveToFile(filename,gameName:string;gameId:TGuid);
var
  attributes:TStringArray;
begin
  //Add the game root with name and Id as attributes

  attributes:=TStringArray.create('name',gameName,'id',GuidToString(gameId));
  addSection('nonogram-game-v1',attributes);
  addNode('nonogram-game-v1','game-block');
  addNode('game-block','game-cells','',TStringArray.create('row','0'));
  addNode('game-cells','game-cell','',TStringArray.create('col','0'));
  addNode('game-cell','row','0');
  addNode('game-cell','col','0');
  addNode('game-cell','colour','#000000');
  addNode('game-cells','game-cell','',TStringArray.create('col','1'));
  addNode('game-cell','row','0');
  addNode('game-cell','col','1');
  addNode('game-cell','colour','#000000');

  save(fileName);
end;

procedure TNonogramDocumentHandler.loadFromFile(filename: string);
begin

end;

//Private methods
procedure TNonogramDocumentHandler.addGameCells(cells: TGameCells;
  rowNo: integer);
begin

end;

procedure TNonogramDocumentHandler.addGameCell(cell: TGameCell; colNo: integer);
begin

end;

procedure TNonogramDocumentHandler.addRowClues(clues: TClueCells; rowNo: integer
  );
begin

end;

procedure TNonogramDocumentHandler.addRowClue(clue: TClueCell;
  clueIndex: integer);
begin

end;

procedure TNonogramDocumentHandler.addColumnClues(clues: TClueCells;
  colNo: integer);
begin

end;

procedure TNonogramDocumentHandler.addColumnClue(clue: TClueCell;
  clueIndex: integer);
begin

end;


end.

