unit nonoDocHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,xml_doc_handler,gameBlock,gameCell,clueCell,graphics,typinfo,enums,laz2_DOM;
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

//Public methods
procedure TNonogramDocumentHandler.saveToFile(filename,gameName:string;gameId:TGuid);
var
  attributes,gameCellsAttributes,gameCellAttributes:TStringArray;
  row,col:integer;
  gameCell:TGameCell;
  fillStr:string;
  gameNode,gameBlockNode,gameCellsNode,gameCellNode:TDomNode;
begin
  if fGameBlock.size = 0 then exit;
  attributes:=TStringArray.create('name',gameName,'id',GuidToString(gameId));
  gameNode:= addSection('nonogram-game-v1',attributes);
  gameBlockNode:=createNode('game-block');
  for row:=0 to pred(fGameBlock.size) do
    begin
    gameCellsNode:=createNode('game-cells');
    for col:=0 to pred(fGameBlock[0].size) do
      begin
      gameCell:=fGameBlock[row][col];
      gameCellNode:=createNode('game-cell');
      gameCellNode.AppendChild(createNode('row',gameCell.row.ToString));
      gameCellNode.AppendChild(createNode('col',gameCell.col.ToString));
      gameCellNode.AppendChild(createNode('colour',colorToString(gameCell.colour)));
      writeStr(fillStr, GetEnumName(TypeInfo(ECellFillMode), ord(gameCell.fill)));
      gameCellNode.AppendChild(createNode('fill-mode',fillStr));
      addNode(gameCellsNode,gameCellNode);
      end;
    end;
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

