unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, nonogramGame, Graphics, arrayUtils,clickDelegate,updateDelegate,gameCell;

type

  { TGameDisplay }

  TGameDisplay = class(TCustomPanel)
  private
    fGame: TNonogramGame;
    fGameCells: TPaintbox;
    fOnGameKeyDown: TKeyEvent;
    fOnGameClick:TNotifyEvent;
    fSelStart:TPoint;
    fSelEnd:TPoint;
    fMultiSelect:boolean;
    procedure initialiseView;
    function getCellSize:integer;
    function getRows:integer;
    function getColumns:integer;
    function getMarginLeft:integer;
    function getMarginTop:integer;
    function getCoords(x,y:integer):TPoint;
    procedure resetSelection;
    //receives input from the game regarding changes to the state
    procedure onGameCellChangedHandler(Sender: TObject);
    procedure drawCell(Sender:TObject);
    procedure onResizeDisplay(Sender: TObject);
    property cellwidth:integer read getcellSize;
    property cellheight:integer read getCellSize;
    property rows:integer read getRows;
    property columns:integer read getcolumns;
    property marginLeft:integer read getMarginLeft;
    property marginTop:integer read getMarginTop;
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

function TGameDisplay.getMarginLeft: integer;
begin
  result:= (fGameCells.Width - (cellWidth * columns)) div 2;
end;

function TGameDisplay.getMarginTop: integer;
begin
  result:=(fGameCells.Height - (cellHeight * rows)) div 2;
end;

function TGameDisplay.getCoords(x, y: integer): TPoint;
var
  rowNo,ColNo:integer;
begin
  rowNo:= (y-marginTop) div cellHeight;
  if (rowNo < 0) or (rowNo > pred(rows)) then rowNo:=-1;
  colNo:=(x-marginLeft) div cellWidth;
  if (colNo < 0) or (colNo > pred(columns)) then colNo:=-1;
  result:=TPoint.Create(colNo,rowNo);
end;

procedure TGameDisplay.resetSelection;
begin
  fSelStart.X:=-1;
  fSelStart.Y:=-1;
  fSelEnd.X:=-1;
  fSelEnd.Y:=-1;
end;

procedure TGameDisplay.onGameCellChangedHandler(Sender: TObject);
begin
  //for changes signalled by the game - triggers redraw of specified area

  if sender is TUpdateDelegate then with sender as TUpdateDelegate do
  fGameCells.Repaint;
end;

procedure TGameDisplay.drawCell(Sender: TObject);
var
  row,column:integer;
  currentCell: TGameCell;
  cellCoords:TRect;

  function getCellCoords(column,row:integer):TRect;
  var
    left,top,right,bottom:integer;
  begin
    left:=marginLeft+(cellwidth * column);
    top:=marginTop+(cellHeight * row);
    right:=marginLeft+(cellWidth * (column+1));
    bottom:=marginTop+(cellHeight * (row + 1));
    result:=TRect.Create(left,top,right,bottom);
  end;

begin
  if sender is TPaintbox then with sender as TPaintbox do
  begin
    //draw the cells
    canvas.Brush.color:=clYellow;
    canvas.Rectangle(0,0,canvas.Width,canvas.Height);
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

procedure TGameDisplay.onResizeDisplay(Sender: TObject);
begin
  //Try to keep aspect ratio
  self.Height := self.Width;
  //resize all the gameCells
end;

procedure TGameDisplay.PaintboxKeyDownHandler(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if Assigned(fOnGameKeyDown) then fOnGameKeyDown(Sender, key, shift);
end;

procedure TGameDisplay.PaintboxMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //send delegate on mouse up
  fSelStart:=getCoords(x,y);
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
      then fSelEnd:=getCoords(x,y)
      else fSelEnd:=fSelStart;
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
  onResize := @onResizeDisplay;
  fGameCells := TPaintbox.Create(aOwner);
  fMultiSelect:=false;
  with fGameCells do
  begin
    Parent := self;
    Align:=alClient;
    OnMouseDown := @PaintBoxMouseDownHandler;
    OnMouseUp:= @PaintBoxMouseUpHandler;
    OnPaint := @DrawCell;
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
