unit xml_doc_handler;

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils,
  laz2_DOM,
  laz2_XMLRead,
  laz2_XMLWrite,
  laz2_XMLUtils;

type
  { TXMLDocumentHandler }

  TXMLDocumentHandler = class(TInterfacedObject)
    private
    fDocument:TXMLDocument;
    protected
    function createNode(name:string;text:string='';attributes:TStringArray=nil):TDomNode;
    function createTextNode(name:string):TDomNode;
    function findInXML(
      startNode: TDomNode;
      nodeName: string;
      attributes:TStringArray;
      findTextValue: boolean): TDomNode;
    function addNode(
      parent, child: string;
      Text: string = '';
      attributes:TStringArray = nil;
      parentAttributes:TStringArray = nil):TDOMNode;
    function addNode(
      parent, child: TDOMNode;
      Text: string = '';
      attributes: TStringArray = nil): TDOMNode;
    function getNode(
      node: TDOMNode;
      nodeAttributes:TStringArray = nil;
      findTextValue: boolean=false): TDOMNode;
    procedure initializeDocument;
    public
    procedure setDocument(doc:TXMLDocument);
    function attachTopLevelNode(sectionName: string;attributes:TStringArray=nil; path:string = ''; value:string = ''):TDomNode;
    function getNode(
      nodeName: string;
      nodeAttributes:TStringArray = nil;
      findTextValue: boolean=false;
      parent:TDOMNode=nil;
      addIfNotFound:boolean=false): TDomNode;
    procedure load(filename: string);
    procedure save(filename: string);
    property document:TXMLDocument read fDocument write setDocument;
  end;


implementation

{ TXMLDocumentHandler }
procedure TXMLDocumentHandler.load(filename: string);
begin
  try
    if FileExists(filename) then
    ReadXMLFile(fDocument, filename)
    else initializeDocument;
    except
      //log an error
    end;
end;

procedure TXMLDocumentHandler.save(filename: string);
begin
  if fDocument = nil then exit;
  writeXMLFile(fDocument, filename);
end;

function TXMLDocumentHandler.createNode(name: string;text:string;attributes:TStringArray): TDomNode;
var
  attrIndex:integer;
begin
  if document = nil then initializeDocument;
  result:=document.CreateElement(name);
  if (text <> '') then result.AppendChild(createTextNode(text));
  if length(attributes) > 0 then
    begin
    attrIndex:=0;
    while attrIndex < pred(length(attributes)) do
      begin
      TDOMElement(result).SetAttribute(attributes[attrIndex], attributes[attrIndex+1]);
      attrIndex:=attrIndex + 2;
      end;
    end;
end;

function TXMLDocumentHandler.createTextNode(name: string): TDomNode;
begin
  if document = nil then initializeDocument;
  result:=document.CreateTextNode(name);
end;

function TXMLDocumentHandler.findInXML(startNode: TDomNode; nodeName: string;
  attributes:TStringArray;findTextValue: boolean): TDomNode;
var
  Count: integer;
  currentNodeName: string;
  attributeId:integer;
  attributeKey,attributeValue:string;
  nodeMatches:boolean;
begin
  if document = nil then initializeDocument;
  Result := nil;
  If startNode = nil then exit;
  if findTextValue then
    currentNodeName := startNode.textContent
  else
    currentNodeName := startNode.NodeName;
  if currentNodeName = nodeName then
    begin
    if (length(attributes)>0) then
      begin
      if (startNode.HasAttributes)
      and (startNode.Attributes.Length = length(attributes) div 2) then
        begin
        nodeMatches:=true;
        for attributeId:=0 to pred(length(attributes))do
          begin
          //every second entry in attributes will be the key
          if (attributeId mod 2 = 0) then attributeKey:=attributes[attributeId] else
            begin
            attributeValue:=attributes[attributeId];
            if (startNode.Attributes.GetNamedItem(attributeKey).TextContent <> attributeValue)
              then nodeMatches:=false;
            end;
          end;
        end;
      end else nodeMatches:=true;
    end else nodeMatches:= false;
  if nodeMatches then result:=startNode
    else if startNode.ChildNodes.Count > 0 then
    for Count := 0 to pred(startNode.ChildNodes.Count) do
    begin
      Result := findInXml(startNode.ChildNodes[Count], nodeName, attributes,findTextValue);
      if Result <> nil then
        exit;
    end;
end;

function TXMLDocumentHandler.addNode(parent, child: string; Text: string;
  attributes: TStringArray; parentAttributes: TStringArray): TDOMNode;
var
  parentNode, childNode: TDOMNode;
begin
  if document = nil then initializeDocument;
  if parent <> '#document' then
    begin
    parentNode := getNode(parent,parentAttributes);
    if parentNode = nil then exit;
    end else parentNode:= nil;
  childNode := createNode(child);
  result:= addNode(parentNode,childNode,text,attributes);
end;

function TXMLDocumentHandler.addNode(parent, child: TDOMNode; Text: string;
  attributes: TStringArray): TDOMNode;
var
  textNode: TDOMNode;
  attrIndex:integer;
begin
  if document = nil then initializeDocument;
  if (parent = nil) then parent:= document;
  if child = nil then exit;

  if (Text <> '') then
    begin
    textNode:= CreateTextNode(Text);
    child.AppendChild(textNode);
    end;

  if length(attributes) > 0 then
    attrIndex:=0;
    while attrIndex < pred(length(attributes)) do
      begin
      TDOMElement(child).SetAttribute(attributes[attrIndex], attributes[attrIndex+1]);
      attrIndex:=attrIndex + 2;
      end;
  parent.AppendChild(child);
  result:= child;
end;

function TXMLDocumentHandler.getNode(node: TDOMNode; nodeAttributes:TStringArray; findTextValue: boolean): TDOMNode;
begin
  result:=getNode(node.NodeName, nodeAttributes, findTextValue);
end;

function TXMLDocumentHandler.getNode(nodeName: string;nodeAttributes:TStringArray;
  findTextValue: boolean; parent: TDOMNode; addIfNotFound: boolean): TDomNode;
var
  startNode,foundNode: TDomNode;
begin
  if document = nil then initializeDocument;

  //if nodename is an empty string return the first child node of the document
  if (nodeName = '') then
    begin
    if (document.GetChildCount > 0)
      then result:=document.ChildNodes.Item[0]
      else result:=nil;
    exit;
    end;

  if parent = nil then
     startNode := document
  else startNode:= parent;
  foundNode := findInXml(startNode, nodeName, nodeAttributes, findTextValue);
  if (foundNode = nil) and (addIfNotFound) then
    foundNode:= addNode(startNode.NodeName,nodeName);
  result:= foundNode;
end;

procedure TXMLDocumentHandler.initializeDocument;
begin
  fDocument:=TXMLDocument.Create;
  //add root node
end;


procedure TXMLDocumentHandler.setDocument(doc: TXMLDocument);
begin
  fDocument:=doc;
end;

function TXMLDocumentHandler.attachTopLevelNode(sectionName: string; attributes:TStringArray=nil; path:string = ''; value:string = ''):TDomNode;
var
  pathParts:TStringArray;
  currentNode:TDOMNode;
  pathIndex:integer;
begin
  //split the path on / and for each portion either find it or add it
  if document = nil then initializeDocument;
  currentNode:= document;//top level
  if (path <> '') then
    begin
    pathParts:= path.Split('/');
    for pathIndex:= 0 to pred(length(pathParts)) do
      currentNode:= getNode(pathParts[pathIndex],attributes,False,currentNode,true);
    end;
  result:= addNode(currentNode.NodeName,sectionName,value,attributes);
end;


end.

