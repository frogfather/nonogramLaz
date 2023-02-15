unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls,StdCtrls, ExtCtrls,dialogs, nonogramGame,
  Graphics, arrayUtils,clickDelegate,updateDelegate,gameModeChangedDelegate,
  cluechangeddelegate,clueclickeddelegate,gameCell,
  clueCell,enums,drawingUtils,newgamedialog,fileUtilities,nonoSolver;

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
    fMode:TButton;
    fNewGame:TButton;
    fLoadGame:TButton;
    fSaveGame:TButton;
    fSolveGame:TButton;
    fOnGameKeyDown: TKeyEvent;
    fOnGameClick:TNotifyEvent;
    fOnClueKeyDown:TKeyEvent;
    fOnClueClick:TNotifyEvent;
    fSelStart:TPoint;
    fSelEnd:TPoint;
    fMultiSelect:boolean;
    fNewGameDialog:TfNewGameDialog;
    fLoadDialog:TOpenDialog;
    fSaveDialog:TSaveDialog;
    procedure recalculateView;
    function getCellSize:integer;
    function getRows:integer;
    function getColumns:integer;
    function getCellLocation(x,y:integer):TPoint; //Get the column and row of the cell from coordinates
    function getCellCoords(column,row:integer):TRect; //Get the bounds of the cell on the paintbox
    procedure resetSelection;
    procedure drawSingleClueCell(canvas_:TCanvas;coords:TRect;clue:TClueCell;isRow:boolean=true);
    function getClueRect(available:TRect):TRect;
    //receives input from the game regarding changes to the state
    procedure onGameCellChangedHandler(Sender: TObject);
    procedure onGameModeChangedHandler(Sender:TObject);
    procedure onClueChangedHandler(Sender:TObject);
    procedure drawSingleGameCell(canvas_:TCanvas;location:TRect;
      fillColour,borderColour:TColor;withCross:boolean=False;withDot:boolean=False);
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
    procedure GameMouseDownHandler(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GameMouseUpHandler(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RowMouseDownHandler(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ColumnMouseDownHandler(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ButtonClickHandler(sender:TObject);
    procedure NewGameClickHandler(sender:TObject);
    procedure GameLoadClickHandler(sender:TObject);
    procedure GameSaveClickHandler(sender:TObject);
    procedure GameSolveClickHandler(sender:TObject);
    procedure keyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor Create(aOwner: TComponent; dimensions: TPoint); reintroduce;
    procedure setGame(aGame: TNonogramGame);
    //property gameCells: TCellDisplayArray read fGameCells;
  published
    property OnGameKeyDown: TKeyEvent read fOnGameKeyDown write fOnGameKeyDown;
    property OnGameClick: TNotifyEvent read fOnGameClick write fOnGameClick;
    property OnClueKeyDown: TKeyEvent read fOnClueKeyDown write fOnClueKeyDown;
    property OnClueClick: TNotifyEvent read fOnClueClick write fOnClueClick;
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
  onKeyDown:=@KeyDownHandler;
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
  fMode:=TButton.create(self);
  with fMode do
    begin
    parent:=fControls;
    name:='bMode';
    left:=fForward.Left+ fForward.Width + 2;
    onClick:=@ButtonClickHandler;
    visible:=true;
    default:=false;
    caption:='Set';
    end;
  fNewGame:=TButton.Create(self);
  with fNewGame do
    begin
    parent:=fControls;
    name:='bNewGame';
    left:=fMode.Left+fMode.Width + 2;
    onClick:=@NewGameClickHandler;
    visible:=true;
    default:=false;
    caption:='New';
    end;
  fSaveGame:=TButton.create(self);
  with fSaveGame do
    begin
    parent:=fControls;
    name:='bSaveGame';
    left:=fNewGame.Left + fnewGame.Width + 2;
    onClick:=@GameSaveClickHandler;
    visible:=true;
    default:=false;
    caption:='Save';
    end;
  fSolveGame:=TButton.create(self);
  with fSolveGame do
    begin
    parent:=fControls;
    name:='bSolveGame';
    left:=fSaveGame.Left + fsaveGame.Width + 2;
    onClick:=@GameSolveClickHandler;
    visible:=true;
    default:=false;
    caption:='Solve';
    end;
  fLoadGame:=TButton.create(self);
  with fLoadGame do
    begin
    parent:=fControls;
    name:='bLoadGame';
    left:=fSolveGame.Left + fsolveGame.Width + 2;
    onClick:=@GameLoadClickHandler;
    visible:=true;
    default:=false;
    caption:='Load';
    end;
  fGameCells := TPaintbox.Create(aOwner);
  with fGameCells do
  begin
    Parent := self;
    Align:=alClient;
    name:='gameCells';
    OnMouseDown := @GameMouseDownHandler;
    OnMouseUp:= @GameMouseUpHandler;
    OnPaint := @DrawGameCells;
  end;
  fRowClues:= TPaintbox.Create(aOwner);
  with fRowClues do
    begin
    Parent := self;
    Align:=alLeft;
    name:='rowClueCells';
    OnMouseDown:=@RowMouseDownHandler;
    OnPaint:=@DrawRowClues;
    end;
  fColumnClues:=TPaintbox.Create(aOwner);
  with fColumnClues do
    begin
    Parent := self;
    Align:=alTop;
    name:='columnClueCells';
    OnMouseDown:=@ColumnMouseDownHandler;
    OnPaint:=@DrawColumnClues;
    end;
end;

procedure TGameDisplay.recalculateView;
var
  maxRowClues,maxColClues:integer;
begin
  if not assigned(fGame) then exit;
  maxRowClues:=fGame.rowClues.maxClues;
  maxColClues:=fGame.columnClues.maxClues;
  if (maxRowClues = 0) then maxRowClues:=1;
  if (maxColClues = 0) then maxColClues:=1;
  fRowClues.Width:= (maxRowClues + 1) * cellWidth;
  fColumnClues.Height:= (maxColClues + 1) * cellheight;
  if fGame.gameMode = gmSet then fMode.Caption:='Set' else fMode.Caption:='Solve';
end;

function TGameDisplay.getCellSize: integer;
var
  cWidth,cHeight:integer;
begin
  if not assigned(fGame) then exit;
  cWidth:=fGameCells.Width div fGame.dimensions.Y;
  cHeight:=fGameCells.Height div fGame.dimensions.X;
  if cWidth < cHeight
    then result:= cWidth
  else result:=cHeight;
end;

function TGameDisplay.getRows: integer;
begin
  if not assigned(fGame) then exit;
  result:=fGame.dimensions.Y
end;

function TGameDisplay.getColumns: integer;
begin
  if not assigned(fGame) then exit;
  result:=fGame.dimensions.X
end;

function TGameDisplay.getCellLocation(x, y: integer): TPoint;
var
  rowNo,ColNo:integer;
begin
  if not assigned(fGame) then exit;
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
  if not assigned(fGame) then exit;
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

function TGameDisplay.getClueRect(available: TRect): TRect;
var
  cellHBorder,cellVBorder: integer;
begin
  cellHBorder:=(available.Right-available.Left) div 10;
  cellVBorder:=(available.Bottom - available.Top) div 10;
  if (cellHBorder = 0) then cellHBorder:=1;
  if (cellVBorder = 0) then cellVBorder:=1;
  result.Left:=available.Left+cellHBorder;
  result.Right:=available.Right-cellHBorder;
  result.Top:=available.Top+cellVBorder;
  result.Bottom:=available.Bottom-cellVBorder;
end;

procedure TGameDisplay.drawSingleClueCell(canvas_: TCanvas; coords: TRect;
  clue: TClueCell;isRow:boolean);
var
    cellRect:TRect;
    widthOfText,heightOfText,textLeft,textTop,widthOfCell,heightOfCell:integer;
begin
  //draw a rectangle at the position indicated
  //If gameMode is set then draw a focus rectangle if the cell is selected
  if not assigned(canvas_) then exit;
  with canvas_ do
    begin
    brush.color:=clue.colour;
    //set font colour depending on brush colour
    font.Color:=clWhite;

    if (isRow and (clue.row = fgame.selectedRowClueSet) and (clue.index = fgame.SelectedRowClueIndex))
    or ((isRow=false) and (clue.column = fGame.selectedColumnClueSet) and (clue.index = fGame.selectedColumnClueIndex))

    then pen.color:=clLime else pen.color:=clDkGray;

    cellRect:=getClueRect(coords);
    RoundRect(cellRect,4,4);
    pen.color:=clDkGray;
    widthOfCell:=cellRect.Right-cellRect.Left;
    heightOfCell:=cellRect.Bottom - cellRect.Top;
    font.Height:= (widthOfCell * 7)div 10;
    widthOfText:=TextWidth(clue.value.ToString);
    heightOfText:=TextHeight(clue.value.ToString);
    textLeft:=cellRect.Left+((widthOfCell - widthOftext)div 2);
    textTop:=cellRect.Top + ((heightOfCell - heightOfText)div 2);
    if (clue.value > -1) then textOut(textLeft, textTop ,clue.value.ToString);
    end;
end;

//for changes signalled by the game - at the moment it just triggers redraw
procedure TGameDisplay.onGameCellChangedHandler(Sender: TObject);
begin
  if sender is TUpdateDelegate then with sender as TUpdateDelegate do
  fGameCells.Repaint;
end;

procedure TGameDisplay.onGameModeChangedHandler(Sender: TObject);
begin
  if sender is TGameModeChangedDelegate then with sender as TGameModeChangedDelegate do
    begin
    if (gameMode = gmSet) then fMode.caption:='Set' else fMode.caption:='Solve';
    fNewGame.visible:=(gameMode=gmSet);
    fSaveGame.visible:=(gameMode=gmSet);
    end;
end;

procedure TGameDisplay.onClueChangedHandler(Sender: TObject);
begin
  if sender is TClueChangedDelegate
    then with sender as TClueChangedDelegate do
    begin
    if resize then recalculateView else
    if isRow then fRowClues.Repaint else
      fColumnClues.Repaint;
    end;
end;

procedure TGameDisplay.drawSingleGameCell(canvas_: TCanvas; location: TRect;
  fillColour, borderColour: TColor;withCross:boolean=False;withDot:boolean=False);
var
    dotDimensions:TRect;
    cellCentre:TPoint;
    dotWidth,dotHeight:integer;
begin
  with canvas_ do
  begin
  Pen.Color:=borderColour;
  Brush.Color:=fillColour;
  Pen.Style:=psClear;
  rectangle(location);
  drawFrame(canvas_,location);
  if withCross then
    begin
    canvas.MoveTo(location.TopLeft);
    canvas.LineTo(location.BottomRight);
    canvas.MoveTo(location.Left,location.Bottom);
    canvas.MoveTo(location.Right,location.Top);
    end;
  if withDot then
    begin
    Pen.Color:=clWhite;
    Brush.Color:=clWhite;
    //draw circle in middle of cell
    cellCentre.X:=location.Left+((location.Right - location.Left) div 2);
    cellCentre.Y:=location.Top+((location.Bottom - location.Top) div 2);
    dotWidth:=(location.Right - location.Left) div 5;
    dotHeight:=(location.Bottom - location.Top)div 5;
    if dotWidth = 0 then dotWidth:=1;
    if dotHeight = 0 then dotheight:=1;
    dotDimensions.Left:=cellCentre.X-dotWidth;
    dotDimensions.Right:=cellCentre.X+dotWidth;
    dotDimensions.Top:=cellCentre.Y - dotWidth;
    dotDimensions.Bottom:=cellCentre.Y + dotWidth;
    canvas.Ellipse(dotDimensions);
    Pen.Color:=borderColour;
    Brush.Color:=fillColour;
    end;
  end;
end;

procedure TGameDisplay.drawGameCells(Sender: TObject);
var
  row,column:integer;
  currentCell: TGameCell;
  cellCoords:TRect;
begin
  if not assigned(fGame) then exit;
  if sender is TPaintbox then with sender as TPaintbox do
  begin
    if (name <> 'gameCells') then exit;
    //draw the cells
    canvas.Brush.color:=clDefault;
    for row:=0 to pred(rows) do
      for column:= 0 to pred(columns) do
        begin
        currentCell:=fGame.getCell(row,column);
        cellCoords:=getCellCoords(column,row);
        case currentCell.fill of
          cfEmpty: drawSingleGameCell(canvas,cellCoords,clDefault,clBlack);
          cfFill:  drawSingleGameCell(canvas,cellCoords,currentCell.colour,$121212);
          cfCross: drawSingleGameCell(canvas,cellCoords,clDefault,clBlack,true);
          cfDot:   drawSingleGameCell(Canvas,cellCoords,clDefault,clBlack,false,true);
        end;
      end;
  end;
end;

procedure TGameDisplay.drawRowClues(Sender: TObject);
var
  rowNo,clueIndex:integer;
  clueAreaHeight:integer;
  clueDimensions:TRect;
begin
  if not assigned(fGame) then exit;
  if sender is TPaintbox then with sender as TPaintbox do
    begin
    if (name <> 'rowClueCells') then exit;
    clueAreaHeight:=(cellHeight * fGame.dimensions.Y)+1;
    canvas.Brush.Color:=$CACBD7;
    canvas.Pen.Style:=psClear;
    canvas.Rectangle(0,0,clientRect.Width,clueAreaHeight);
    canvas.pen.style:=psSolid;
    canvas.pen.color:=clBlack;
    canvas.MoveTo(0,0);
    canvas.LineTo(0,clueAreaHeight);
    for rowno:=0 to fGame.dimensions.Y do
      begin
      canvas.moveTo(0, (cellHeight*rowNo)+1);
      canvas.lineTo(canvas.Width, (cellHeight*rowNo)+1);
      for clueIndex:=0 to pred(fGame.rowClues[rowNo].size) do
        begin
        clueDimensions.Left:=ClientRect.Width - (cellWidth * (clueIndex + 1));
        clueDimensions.Right:=clueDimensions.left + cellWidth;
        clueDimensions.Top:=(rowNo * cellheight)+canvas.Pen.Width;
        clueDimensions.Bottom:=clueDimensions.Top + cellheight;
        drawSingleClueCell(canvas,clueDimensions,fGame.rowClues[rowNo][clueIndex]);
        end;
      end;
    end;

  SetFocus;
end;

procedure TGameDisplay.drawColumnClues(Sender: TObject);
var
  columnNo,clueIndex:integer;
  clueAreaWidth:integer;
  clueDimensions:TRect;
begin
  if not assigned(fGame) then exit;
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
      for clueIndex:=0 to pred(fGame.ColumnClues[columnNo].size) do
        begin
        clueDimensions.Top:=ClientRect.Height - (cellheight * (clueIndex + 1));
        clueDimensions.Bottom:=clueDimensions.Top + cellWidth;
        clueDimensions.left:= fRowClues.Width + (columnNo * cellWidth)+canvas.Pen.Width;
        clueDimensions.Right:=clueDimensions.Left + cellWidth;
        drawSingleClueCell(canvas,clueDimensions,fGame.columnClues[columnNo][clueIndex],false);
        end;
      end;
    end;
end;

procedure TGameDisplay.onResizeDisplay(Sender: TObject);
begin
  fGameCells.Repaint;
  fColumnClues.Repaint;
  fRowClues.Repaint;
  recalculateView;
end;

//Instead of on click events we'll use mouse down and mouse up.
//This allows selection of multiple cells
procedure TGameDisplay.GameMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //send delegate on mouse up
  fSelStart:=getCellLocation(x,y);
  if (fSelStart.X = -1)or(fSelStart.Y=-1) then resetSelection;
end;

procedure TGameDisplay.GameMouseUpHandler(Sender: TObject;
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

procedure TGameDisplay.RowMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  row_,index_:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
  begin
  row_:=Y div cellwidth;
  index_:=(clientRect.Width - X) div cellWidth;
  if Assigned(fOnClueClick) then fOnClueClick(TClueClickDelegate.create(row_,index_));
  end;
end;

procedure TGameDisplay.ColumnMouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  column_,index_:integer;
begin
  if sender is TPaintbox then with sender as TPaintbox do
  begin
  column_:= (X - fRowClues.Width) div cellWidth;
  index_:= (ClientRect.Height - Y) div cellHeight;
  if Assigned(fOnClueClick) then fOnClueClick(TClueClickDelegate.create(column_,index_,false));
  end;
end;

//Signals clicks on display buttons to the game
procedure TGameDisplay.ButtonClickHandler(sender: TObject);
var
  key:Word;
begin
  if sender is TButton then with sender as TButton do
    begin
    case name of
      'bBack': key:=66; //b
      'bForward': key:=70; //f
      'bMode': key:=83; //s
    end;
    if Assigned(fOnGameKeyDown) then fOnGameKeyDown(Sender, key, []);
    end;
end;

procedure TGameDisplay.NewGameClickHandler(sender: TObject);
begin
  fNewGameDialog:=TfNewGameDialog.Create(self);
  fNewGameDialog.showModal;
  if fNewGameDialog.ModalResult=mrOK then
    setGame(TNonogramGame.create(fNewGameDialog.eName.Text,fNewGameDialog.dimensions));
end;

procedure TGameDisplay.GameLoadClickHandler(sender: TObject);
begin
  fLoadDialog:=TOpenDialog.Create(self);
  if fLoadDialog.Execute then
    begin
    setGame(TNonogramGame.create(fLoadDialog.FileName));
    end;
end;

procedure TGameDisplay.GameSaveClickHandler(sender: TObject);
var
  userDir:string;
begin
  //save the current game
  if assigned(fGame) then
    begin
    userDir:=getUsrDir('cloudsoft');
    SetCurrentDir(userdir+'/Downloads');
    fSaveDialog:=TSaveDialog.Create(self);
    fSaveDialog.InitialDir:=userDir+'/Downloads';
    fSaveDialog.FileName:=fGame.name+'.xml';
    if fSaveDialog.Execute then
      begin
      fGame.saveToFile(fSaveDialog.FileName);
      end;
    end;
end;

procedure TGameDisplay.GameSolveClickHandler(sender: TObject);
begin
  fGame.solver:=TNonogramSolver.create;
  fGame.solveGame;
end;

procedure TGameDisplay.keyDownHandler(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not assigned(fOnClueKeyDown) then exit;
  if sender is TGameDisplay then with sender as TGameDisplay do
   begin
   fOnClueKeyDown(sender,key,shift);
   end;
end;

procedure TGameDisplay.setGame(aGame: TNonogramGame);
begin
  fGame:= aGame;
  //assign onGameCellChangedHandler method in this class to the notify event
  //in the game to allow the game to signal that something has changed
  fGame.setCellChangedHandler(@onGameCellChangedHandler);
  fGame.setGameModeChangedHandler(@onGameModeChangedHandler);
  fGame.setClueChangedHandler(@onClueChangedHandler);
  //assigns the notify event for a key press in this class to the handler in the game
  onGameKeyDown := @fGame.gameInputKeyPressHandler;
  onGameClick:= @fGame.gameInputClickHandler;
  onClueKeyDown:=@fGame.clueInputKeyPressHandler;
  onClueClick:=@fGame.clueInputClickHandler;
  recalculateView;
end;

end.
