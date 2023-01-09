unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, nonogramGame, Graphics, arrayUtils,clickDelegate,updateDelegate,gameCell,enumns;

type

  { TGameDisplay }

  TGameDisplay = class(TCustomPanel)
  private
    fGame: TNonogramGame;
    fGameCells: TPaintbox;
    fRowClues: TPaintbox;
    fColumnClues: TPaintbox;
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
    procedure drawGameCell(Sender:TObject);
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
    procedure PaintboxKeyDownHandler(Sender: TObject; var Key: word; Shift: TShiftState);
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
  fGameCells := TPaintbox.Create(aOwner);
  with fGameCells do
  begin
    Parent := self;
    Align:=alClient;
    name:='gameCells';
    OnMouseDown := @PaintBoxMouseDownHandler;
    OnMouseUp:= @PaintBoxMouseUpHandler;
    OnPaint := @DrawGameCell;
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
  left_:= (cellwidth * column);
  top_:= (cellHeight * row);
  right_:= (cellWidth * (column+1));
  bottom_:= (cellHeight * (row + 1));
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

procedure TGameDisplay.drawGameCell(Sender: TObject);
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
          cfEmpty:
            begin
            canvas.Brush.color:=clDefault;
            canvas.Rectangle(cellCoords);
            end;
          cfFill:
            begin
            canvas.Brush.color:=currentCell.colour;
            canvas.Rectangle(cellCoords);
            end;
          cfCross:
            begin
            canvas.Brush.color:=clDefault;
            canvas.Rectangle(cellCoords);
            canvas.MoveTo(cellCoords.TopLeft);
            canvas.LineTo(cellCoords.BottomRight);
            canvas.MoveTo(cellCoords.Left,cellCoords.Bottom);
            canvas.MoveTo(cellCoords.Right,cellCoords.Top);
            end;
          cfDot:
            begin
            canvas.Brush.color:=clDefault;
            canvas.Rectangle(cellCoords);
            canvas.TextOut(cellCoords.Top,cellcoords.Left,'o');
            end;
        end;
      end;
  end;
end;

procedure TGameDisplay.drawRowClues(Sender: TObject);
var
  rowNo:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
    begin
    if (name <> 'rowClueCells') then exit;
    canvas.Brush.Color:=clGray;
    canvas.Rectangle(0,0,canvas.Width,canvas.Height);
    //clues here line up with the grid
    canvas.pen.color:=clBlack;
    for rowno:=0 to fGame.dimensions.Y do
      begin
      canvas.moveTo(0, (cellHeight*rowNo));
      canvas.lineTo(canvas.Width, (cellHeight*rowNo));
      //some way of drawing clues

      end;
    end;
end;

procedure TGameDisplay.drawColumnClues(Sender: TObject);
var
  columnNo:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
    begin
    if (name <> 'columnClueCells') then exit;
    canvas.Brush.Color:=clGray;
    canvas.Rectangle(0,0,canvas.Width,canvas.Height);
    //find the left hand side of the grid
    canvas.Pen.color:=clBlack;
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

procedure TGameDisplay.PaintboxKeyDownHandler(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if Assigned(fOnGameKeyDown) then fOnGameKeyDown(Sender, key, shift);
end;

//Instead of on click events we'll use mouse down and mouse up.
//This allows selection of multiple cells
procedure TGameDisplay.PaintboxMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //send delegate on mouse up
  fSelStart:=getCellLocation(x,y);
  //writeln('fSelStart '+x.toString+','+y.toString+': '+fSelStart.X.toString+','+fSelStart.Y.ToString);
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
