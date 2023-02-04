unit nonoDocHandler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,xml_doc_handler,gameBlock,gameCell,clueCell,graphics,typinfo,enums,laz2_DOM,arrayUtils;
type
  
  { TNonogramDocumentHandler }

  TNonogramDocumentHandler = class(TXMLDocumentHandler)
    private
    fGameBlock:TGameBlock;
    fRowClueBlock:TClueBlock;
    fColumnClueBlock:TClueBlock;
    fId:TGUID;
    fName:string;
    fVersion:string;
    fDimensions:TPoint;
    fColours:TColours;
    fSelectedColour:TColor;
    procedure addGameCells(cells:TGameCells;rowNo:integer);
    procedure addGameCell(cell:TGameCell;colNo:integer);
    procedure addRowClues(clues:TClueCells;rowNo:integer);
    procedure addRowClue(clue:TClueCell;clueIndex:integer);
    procedure addColumnClues(clues:TClueCells;colNo:integer);
    procedure addColumnClue(clue:TClueCell;clueIndex:integer);
    public
    constructor create;
    constructor create(gameBlock_:TGameBlock;rowClueBlock_:TClueBlock;colClueBlock_:TClueBlock);
    property gameBlock:TGameBlock read fGameBlock write fGameBlock;
    property rowClueBlock:TClueBlock read fRowClueBlock write fRowClueBlock;
    property columnClueBlock:TClueBlock read fColumnClueBlock write fColumnClueBlock;
    property id:TGUID read fId write fId;
    property name: string read fName write fName;
    property version: string read fVersion write fVersion;
    property dimensions: TPoint read fDimensions write fDimensions;
    property colours:TColours read fColours write fColours;
    property selectedColour: TColor read fSelectedColour write fSelectedColour;
    procedure saveToFile(filename,gameName:string;gameId:TGuid);
    procedure loadFromFile(filename:string);
  end;


implementation

{ TNonogramDocumentHandler }

  constructor TNonogramDocumentHandler.create;
  begin
    initializeDocument;
    fGameBlock:=nil;
    fRowClueBlock:=nil;
    fColumnClueBlock:=nil;
  end;

  constructor TNonogramDocumentHandler.create(gameBlock_: TGameBlock;
    rowClueBlock_: TClueBlock; colClueBlock_: TClueBlock);
  begin
    initializeDocument;
    fGameBlock:=gameBlock_;
    fRowClueBlock:=rowClueBlock_;
    fColumnClueBlock:=colClueBlock_;
  end;

//Public methods
procedure TNonogramDocumentHandler.saveToFile(filename,gameName:string;gameId:TGuid);
var
  attributes,gameCellAttributes:TStringArray;
  row,col,clueId:integer;
  gameCell:TGameCell;
  rowClue,colClue:TClueCell;
  fillStr:string;
  gameNode,gameBlockNode,gameCellsNode,gameCellNode,rowClueBlockNode,columnClueBlockNode,cluesNode,clueNode:TDomNode;
begin
  if fGameBlock.size = 0 then exit;
  attributes:=TStringArray.create('name',gameName,'id',GuidToString(gameId));
  gameNode:= attachTopLevelNode(version,attributes);//creates a top level node and attaches it to the document

  gameBlockNode:=createNode('game-block');
  for row:=0 to pred(fGameBlock.size) do
    begin
    gameCellsNode:=createNode('game-cells');
    for col:=0 to pred(fGameBlock[0].size) do
      begin
      gameCell:=fGameBlock[row][col];
      gameCellAttributes:=TStringArray.create('cell-id',guidToString(gameCell.cellId));
      gameCellNode:=createNode('game-cell','',gameCellAttributes);
      gameCellNode.AppendChild(createNode('row',gameCell.row.ToString));
      gameCellNode.AppendChild(createNode('col',gameCell.col.ToString));
      gameCellNode.AppendChild(createNode('colour',colorToString(gameCell.colour)));
      writeStr(fillStr, GetEnumName(TypeInfo(ECellFillMode), ord(gameCell.fill)));
      gameCellNode.AppendChild(createNode('fill-mode',fillStr));
      addNode(gameCellsNode,gameCellNode);
      end;
    addNode(gameBlockNode,gameCellsNode);
    end;
  addNode(gameNode,gameBlockNode);

  rowClueBlockNode:=createNode('row-clue-block');
  for row:=0 to pred(rowClueBlock.size) do
    begin
    cluesNode:=createNode('row-clues');
      for clueId:=0 to pred(rowClueBlock[row].size) do
        begin
        rowClue:=rowClueBlock[row][clueId];
        clueNode:=createNode('row-clue','',TStringArray.create('index',rowClue.index.toString));
        clueNode.AppendChild(createNode('row',rowClue.row.ToString));
        clueNode.AppendChild(createNode('col',rowClue.column.ToString));
        clueNode.AppendChild(createNode('colour',colorToString(rowClue.colour)));
        clueNode.AppendChild(createNode('value',rowClue.value.toString));
        clueNode.AppendChild(createNode('solved',BoolToStr(rowClue.solved)));
        addNode(cluesNode,clueNode);
        end;
      addNode(rowClueBlockNode,cluesNode);
    end;
  addNode(gameNode,rowClueBlockNode);

  columnClueBlockNode:=createNode('column-clue-block');
  for col:= 0 to pred(columnClueBlock.size) do
    begin
    cluesNode:=createNode('column-clues');
      for clueId:=0 to pred(columnClueBlock[col].size) do
        begin
        colClue:=columnClueBlock[col][clueId];
        clueNode:=createNode('column-clue','',TStringArray.create('index',colClue.index.toString));
        clueNode.AppendChild(createNode('row',colClue.row.ToString));
        clueNode.AppendChild(createNode('col',colClue.column.ToString));
        clueNode.AppendChild(createNode('colour',colorToString(colClue.colour)));
        clueNode.AppendChild(createNode('value',colClue.value.toString));
        clueNode.AppendChild(createNode('solved',BoolToStr(colClue.solved)));
        addNode(cluesNode,clueNode);
        end;
      addNode(columnClueBlockNode,cluesNode);
    end;
  addNode(gameNode,columnClueBlockNode);

  save(fileName);
end;

procedure TNonogramDocumentHandler.loadFromFile(filename: string);
var
  gameNode,gameBlockNode,gameCellsNode,gameCellNode,gameCellChildNode:TDomNode;
  rowClueBlockNode,columnClueBlockNode,rowCluesNode,columnCluesNode,clueNode,clueChildNode:TDomNode;
  rowIndex,colIndex,clueIndex,propIndex:integer;
  rowId,colId,clueIndexPosition,clueValue: integer;
  fillMode: ECellfillMode;
  cellColour:TColor;
  cellId:TGUID;
  clueSolved:boolean;
  newGameCells:TGameCells;
  newRowClues,newColumnClues:TClueCells;
begin
  load(filename); //creates document from file
  gameNode:=getNode('');
  if not assigned(gameNode) then exit;
  fVersion:=gameNode.NodeName;
  fName:=gameNode.Attributes.GetNamedItem('name').TextContent;
  tryStringToGuid(gameNode.Attributes.GetNamedItem('id').TextContent,fId);
  gameBlockNode:=getNode('game-block',nil,false,gameNode);
  fDimensions.Y:=gameBlockNode.GetChildCount;
  if (fDimensions.Y = 0) then exit; //should raise exception
  fDimensions.X:= gameBlockNode.ChildNodes.Item[0].GetChildCount;
  fGameBlock:=TGameBlock.create;
  for rowIndex:=0 to pred(gameBlockNode.GetChildCount) do
    begin
    newGameCells:=TGameCells.create;
    gameCellsNode:= gameBlockNode.ChildNodes.Item[rowIndex];
    for colIndex:= 0 to pred(gameCellsNode.GetChildCount) do
      begin
      gameCellNode:=gameCellsNode.ChildNodes.Item[colIndex];
      tryStringToGuid(gameCellNode.Attributes.GetNamedItem('cell-id').TextContent,cellId);
      for propIndex:=0 to pred(gameCellNode.GetChildCount) do
        begin
        gameCellChildNode:=gameCellNode.ChildNodes.Item[propIndex];
        if (gameCellChildNode.NodeName = 'row')
          then rowId:=gameCellChildNode.TextContent.ToInteger else
        if (gameCellChildNode.NodeName = 'col')
          then colId:=gameCellChildNode.TextContent.ToInteger else
        if (gameCellChildNode.NodeName = 'colour')
          then cellColour:=StringToColor(gameCellChildNode.TextContent) else
        if (gameCellChildNode.NodeName = 'fill-mode')
          then fillMode:= ECellFillMode(GetEnumValue(TypeInfo(ECellFillMode), gameCellChildNode.TextContent));
        end;
      newGameCells.push(TGameCell.create(colId,rowId,cellId,cellColour,fillMode));
      end;
    fGameBlock.push(newGameCells);
    end;

  rowClueBlockNode:=getNode('row-clue-block',nil,false,gameNode);
  fRowClueBlock:=TClueBlock.Create;
  for rowIndex:=0 to pred(rowClueBlockNode.GetChildCount)do
    begin
    newRowClues:=TClueCells.Create;
    rowCluesNode:=rowClueBlockNode.ChildNodes.Item[rowIndex];
    for clueIndex:=0 to pred(rowCluesNode.GetChildCount) do
      begin
      clueNode:=rowCluesNode.ChildNodes.Item[clueIndex];
      clueIndexPosition:=clueNode.Attributes.GetNamedItem('index').TextContent.ToInteger;
      for propIndex:=0 to pred(clueNode.GetChildCount) do
        begin
        clueChildNode:=clueNode.ChildNodes.Item[propIndex];
        //row,column,colour,value,solved
        if (clueChildNode.NodeName='row')
          then rowId:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='col')
          then colId:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='colour')
          then cellColour:=StringToColor(clueChildNode.TextContent) else
        if (clueChildNode.NodeName='value')
          then clueValue:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='solved')
          then clueSolved:=StrToBool(clueChildNode.TextContent);
        end;
      newRowClues.push(TClueCell.create(rowId,colId,clueValue,clueIndexPosition,cellColour));
      end;
    fRowClueBlock.push(newRowClues);
    end;

  columnClueBlockNode:=getNode('column-clue-block',nil,false,gameNode);
  fColumnClueBlock:=TClueBlock.Create;
  for colIndex:=0 to pred(columnClueBlockNode.GetChildCount)do
    begin
    newColumnClues:=TClueCells.Create;
    columnCluesNode:=columnClueBlockNode.ChildNodes.Item[colIndex];
    for clueIndex:=0 to pred(columnCluesNode.GetChildCount) do
      begin
      clueNode:=columnCluesNode.ChildNodes.Item[clueIndex];
      clueIndexPosition:=clueNode.Attributes.GetNamedItem('index').TextContent.ToInteger;
      for propIndex:=0 to pred(clueNode.GetChildCount) do
        begin
        clueChildNode:=clueNode.ChildNodes.Item[propIndex];
        if (clueChildNode.NodeName='row')
          then rowId:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='col')
          then colId:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='colour')
          then cellColour:=StringToColor(clueChildNode.TextContent) else
        if (clueChildNode.NodeName='value')
          then clueValue:=clueChildNode.TextContent.ToInteger else
        if (clueChildNode.NodeName='solved')
          then clueSolved:=StrToBool(clueChildNode.TextContent);
        end;
      newColumnClues.push(TClueCell.create(rowId,colId,clueValue,clueIndexPosition,cellColour));
      end;
    fColumnClueBlock.push(newColumnClues);
    end;
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

