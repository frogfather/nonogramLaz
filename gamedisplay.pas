unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls,StdCtrls, ExtCtrls, nonogramGame,
  Graphics, arrayUtils,clickDelegate,updateDelegate,gameCell,
  clueCell,enums,drawingUtils;

type

  { TGameDisplay }

  TGameDisplay = class(TCustomPanel)
  private
    fGame: TNonogramGame;
    fGameCells: TPaintbox;
    fRowClues: TPaintbox;
    fColumnClues: TPaintbox;
    fControls:TPanel;
    fBack:TButton;
    fForward:TButton;
    fOnGameKeyDown: TKeyEvent;
    fOnGameClick:TNotifyEvent;
    fSelStart:TPoint;
    fSelEnd:TPoint;
    fMultiSelect:boolean;
    procedure initialiseView;
    function getCellSize:integer;
    function getRows:integer;
    function getColumns:integer;
    function getCellLocation(x,y:integer):TPoint; //Get the column and row of the cell from coordinates
    function getCellCoords(column,row:integer):TRect; //Get the bounds of the cell on the paintbox
    procedure resetSelection;
    procedure drawClue(pb:TPaintbox;coords:TRect);
    //receives input from the game regarding changes to the state
    procedure onGameCellChangedHandler(Sender: TObject);
    procedure drawSingleGameCell(canvas_:TCanvas;location:TRect;fillColour,borderColour:TColor);
    procedure drawGameCells(Sender:TObject);
    procedure drawRowClues(Sender:TObject);
    procedure drawColumnClues(Sender:TObject);
    procedure onResizeDisplay(Sender: TObject);
    property cellwidth:integer read getcellSize;
    property cellheight:integer read getCellSize;
    property rows:integer read getRows;
    property columns:integer read getcolumns;
    property multiSelect:boolean read fMultiSelect write fMultiSelect;
  protected
    //intercepts the onClick event of the paintbox
    procedure PaintboxMouseDownHandler(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintboxMouseUpHandler(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure ButtonClickHandler(sender:TObject);
  public
    constructor Create(aOwner: TComponent; dimensions: TPoint); reintroduce;
    procedure setGame(aGame: TNonogramGame);
    //property gameCells: TCellDisplayArray read fGameCells;
  published
    property OnGameKeyDown: TKeyEvent read fOnGameKeyDown write fOnGameKeyDown;
    property OnGameClick: TNotifyEvent read fOnGameClick write fOnGameClick;
  end;

implementation

{ TGameDisplay }

constructor TGameDisplay.Create(aOwner: TComponent; dimensions: TPoint);
begin
  inherited Create(aOwner);
  Name := 'myGameDisplay';
  Caption := '';
  Height := dimensions.Y;
  Width := dimensions.X;
  fGame := nil;
  fSelStart:=TPoint.Create(-1,-1);
  fSelEnd:= TPoint.Create(-1,-1);
  fMultiSelect:=false;
  onResize := @onResizeDisplay;
  fControls:=TPanel.Create(aOwner);
  with fControls do
    begin
    Parent:=self;
    name:='pControls';
    caption:='';
    align:=alBottom;
    height:=parent.Height div 10;
    visible:=true;
    end;
  fBack:=TButton.create(self);
  with fBack do
    begin
    parent:=fControls;
    name:='bBack';
    left:=10;
    onClick:=@ButtonClickHandler;
    visible:=true;
    default:=false;
    caption:='<';
    end;
  fForward:=TButton.create(self);
  with fForward do
    begin
    parent:=fControls;
    name:='bForward';
    left:=fBack.Left+ fBack.Width + 2;
    onClick:=@ButtonClickHandler;
    visible:=true;
    default:=false;
    caption:='>';
    end;
  fGameCells := TPaintbox.Create(aOwner);
  with fGameCells do
  begin
    Parent := self;
    Align:=alClient;
    name:='gameCells';
    OnMouseDown := @PaintBoxMouseDownHandler;
    OnMouseUp:= @PaintBoxMouseUpHandler;
    OnPaint := @DrawGameCells;
  end;
  fRowClues:= TPaintbox.Create(aOwner);
  with fRowClues do
    begin
    Parent := self;
    Align:=alLeft;
    name:='rowClueCells';
    OnPaint:=@DrawRowClues;
    end;
  fColumnClues:=TPaintbox.Create(aOwner);
  with fColumnClues do
    begin
    Parent := self;
    Align:=alTop;
    name:='columnClueCells';
    OnPaint:=@DrawColumnClues;
    end;
end;

procedure TGameDisplay.initialiseView;
begin

end;

function TGameDisplay.getCellSize: integer;
var
  cWidth,cHeight:integer;
begin
  cWidth:=fGameCells.Width div fGame.dimensions.Y;
  cHeight:=fGameCells.Height div fGame.dimensions.X;
  if cWidth < cHeight
    then result:= cWidth
  else result:=cHeight;
end;

function TGameDisplay.getRows: integer;
begin
  result:=fGame.dimensions.X
end;

function TGameDisplay.getColumns: integer;
begin
  result:=fGame.dimensions.Y
end;

function TGameDisplay.getCellLocation(x, y: integer): TPoint;
var
  rowNo,ColNo:integer;
begin
  rowNo:= y div cellHeight;
  if (rowNo < 0) or (rowNo > pred(rows)) then rowNo:=-1;
  colNo:= x div cellWidth;
  if (colNo < 0) or (colNo > pred(columns)) then colNo:=-1;
  result:=TPoint.Create(colNo,rowNo);
end;

function TGameDisplay.getCellCoords(column, row:integer): TRect;
var
    left_,top_,right_,bottom_:integer;
begin
  left_:= (cellwidth * column)+1;
  top_:= (cellHeight * row)+1;
  right_:= (cellWidth * (column+1)+1);
  bottom_:= (cellHeight * (row + 1)+1);
  result:=TRect.Create(left_,top_,right_,bottom_);
end;

procedure TGameDisplay.resetSelection;
begin
  fSelStart.X:=-1;
  fSelStart.Y:=-1;
  fSelEnd.X:=-1;
  fSelEnd.Y:=-1;
end;

procedure TGameDisplay.drawClue(pb: TPaintbox; coords: TRect);
begin

end;

//for changes signalled by the game - at the moment it just triggers redraw
procedure TGameDisplay.onGameCellChangedHandler(Sender: TObject);
begin
  if sender is TUpdateDelegate then with sender as TUpdateDelegate do
  fGameCells.Repaint;
end;

procedure TGameDisplay.drawSingleGameCell(canvas_: TCanvas; location: TRect;
  fillColour, borderColour: TColor);
begin
  with canvas_ do
  begin
  Pen.Color:=borderColour;
  Brush.Color:=fillColour;
  Pen.Style:=psClear;
  rectangle(location);
  drawFrame(canvas_,location);
  end;
end;

procedure TGameDisplay.drawGameCells(Sender: TObject);
var
  row,column:integer;
  currentCell: TGameCell;
  cellCoords:TRect;
begin
  if sender is TPaintbox then with sender as TPaintbox do
  begin
    if (name <> 'gameCells') then exit;
    //draw the cells
    canvas.Brush.color:=clDefault;
    for row:=0 to pred(rows) do
      for column:= 0 to pred(columns) do
        begin
        //if fill style is none use default colour
        //if fill style is solid use the colour of the cell
        //if fill style is cross, add a cross
        //if fill style is dot add a dot
        currentCell:=fGame.getCell(row,column);
        cellCoords:=getCellCoords(column,row);
        case currentCell.fill of
          cfEmpty: drawSingleGameCell(canvas,cellCoords,clDefault,clBlack);
          cfFill:  drawSingleGameCell(canvas,cellCoords,currentCell.colour,clBlack);
          cfCross:
            begin
            drawSingleGameCell(canvas,cellCoords,clDefault,clBlack);
            canvas.MoveTo(cellCoords.TopLeft);
            canvas.LineTo(cellCoords.BottomRight);
            canvas.MoveTo(cellCoords.Left,cellCoords.Bottom);
            canvas.MoveTo(cellCoords.Right,cellCoords.Top);
            end;
          cfDot:
            begin
            drawSingleGameCell(canvas,cellCoords,clDefault,clBlack);
            //Temporary
            canvas.TextOut(cellCoords.Top,cellcoords.Left,'o');
            end;
        end;
      end;
  end;
end;

procedure TGameDisplay.drawRowClues(Sender: TObject);
var
  rowNo:integer;
  clueAreaHeight:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
    begin
    if (name <> 'rowClueCells') then exit;
    clueAreaHeight:=(cellHeight * fGame.dimensions.Y)+1;
    canvas.Brush.Color:=$CACBD7;
    canvas.Pen.Style:=psClear;
    canvas.Rectangle(0,0,canvas.Width,clueAreaHeight);
    //clues here line up with the grid
    canvas.pen.style:=psSolid;
    canvas.pen.color:=clBlack;
    canvas.MoveTo(0,0);
    canvas.LineTo(0,clueAreaHeight);
    for rowno:=0 to fGame.dimensions.Y do
      begin
      canvas.moveTo(0, (cellHeight*rowNo)+1);
      canvas.lineTo(canvas.Width, (cellHeight*rowNo)+1);
      //some way of drawing clues - preferably taking an array of clues

      end;
    end;
end;

procedure TGameDisplay.drawColumnClues(Sender: TObject);
var
  columnNo:integer;
  clueAreaWidth:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
    begin
    if (name <> 'columnClueCells') then exit;
    clueAreaWidth:= fRowClues.Width + (cellWidth * fGame.dimensions.X)+1;
    canvas.Brush.Color:=$CACBD7;
    canvas.Pen.Style:=psClear;
    canvas.Rectangle(0,0,clueAreaWidth,canvas.Height);
    canvas.pen.style:=psSolid;
    canvas.Pen.color:=clBlack;
    canvas.MoveTo(0,canvas.height);
    canvas.LineTo(0,0);
    canvas.LineTo(clueAreaWidth,0);
    for columnNo:=0 to fGame.dimensions.X do
      begin
      canvas.MoveTo(fGameCells.Left+ (cellWidth*columnNo),0);
      canvas.LineTo(fGameCells.Left+ (cellWidth*columnNo), Canvas.Height);
      end;
    end;
end;

procedure TGameDisplay.onResizeDisplay(Sender: TObject);
begin
  fGameCells.Repaint;
  fColumnClues.Repaint;
  fRowClues.Repaint;
end;

//Instead of on click events we'll use mouse down and mouse up.
//This allows selection of multiple cells
procedure TGameDisplay.PaintboxMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //send delegate on mouse up
  fSelStart:=getCellLocation(x,y);
  if (fSelStart.X = -1)or(fSelStart.Y=-1) then resetSelection;
end;

procedure TGameDisplay.PaintboxMouseUpHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  startx,startY,endX,endY:integer;
  indexX,indexY:integer;
  selectedPoints:TPointArray;
begin
  selectedPoints:=TPointArray.create;
  //if start is set then set end and send delegate
  if (fSelStart.X > -1)and(fSelStart.Y > -1) then
    begin
    if multiSelect
      then fSelEnd:=getCellLocation(x,y)
    else if (getCellLocation(x,y) = fSelStart)
      then fSelEnd:=fSelStart
    else resetSelection;
    end;
  if (fSelEnd.X = -1) or (fSelEnd.Y = -1) then
    begin
    resetSelection;
    exit;
    end;
  //now for the range selected add points
  if (fSelStart.X < fSelEnd.X) then
    begin
    startX:=fSelStart.X;
    endX:=fSelEnd.X;
    end else
    begin
    startX:=fSelEnd.X;
    endX:=fSelStart.X;
    end;
  if (fSelStart.Y < fSelEnd.Y) then
    begin
    startY:=fSelStart.Y;
    endY:=fSelEnd.Y;
    end else
    begin
    startY:=fSelEnd.Y;
    endY:=fSelStart.Y;
    end;
  for indexX:=startX to endX do
    for indexY:= startY to endY do
      selectedPoints.push(TPoint.Create(indexX,indexY));
  if Assigned(fOnGameClick) then fOnGameClick(TClickDelegate.create(selectedPoints));
end;

procedure TGameDisplay.ButtonClickHandler(sender: TObject);
var
  key:Word;
begin
  if sender is TButton then with sender as TButton do
    begin
    case name of
      'bBack': key:=66;
      'bForward': key:=70;
    end;
    if Assigned(fOnGameKeyDown) then fOnGameKeyDown(Sender, key, []);
    end;
end;

procedure TGameDisplay.setGame(aGame: TNonogramGame);
begin
  fGame:= aGame;
  //assign onGameCellChangedHandler method in this class to the notify event
  //in the game to allow the game to signal that something has changed
  fGame.setCellChangedHandler(@onGameCellChangedHandler);
  //assigns the notify event for a key press in this class to the handler in the game
  onGameKeyDown := @fGame.gameInputKeyPressHandler;
  onGameClick:= @fGame.gameInputClickHandler;
  initialiseView;
end;

end.
