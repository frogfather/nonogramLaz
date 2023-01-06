unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, nonogramGame, Graphics, arrayUtils, gameCell,
  gameDisplayInterface,clickDelegate,updateDelegate;

type

  { TCellDisplay }
  TCellDisplay = class(TCustomPanel, ICellDisplay)
  private
    fPaintBox: TPaintbox;
    fRow: integer;
    fColumn: integer;
    fOnCellKeyDown: TKeyEvent;
    fOnCellClick:TNotifyEvent;
    procedure drawCell(Sender: TObject);
  protected
    //intercepts onClick event of the parent object
    procedure CellClickHandler(Sender: TObject);
    //intercepts the onClick event of the paintbox
    procedure PaintboxClickHandler(Sender: TObject);
    //handles key down event in the parent object and signal the method
    //in the game if set
    procedure CellKeyDownHandler(Sender: TObject; var Key: word; Shift: TShiftState);
    property OnCellKeyDown: TKeyEvent read fOnCellKeyDown write fOnCellKeyDown;
    property OnCellClick: TNotifyEvent read fOnCellClick write fOnCellClick;
    function getName: string;
    function getRow: integer;
    function getCol: integer;
  public
    constructor Create(aOwner: TComponent; cCol,cRow: integer); reintroduce;
    property row: integer read getRow;
    property col: integer read getCol;
  end;

  { TCellDisplayArray }
  TCellDisplayArray = array of TCellDisplay;

  { TGameDisplay }

  TGameDisplay = class(TCustomPanel, IGameDisplay)
  private
    fGame: TNonogramGame;
    fGameCells: TCellDisplayArray;
    fOnGameKeyDown: TKeyEvent;
    fOnGameClick:TNotifyEvent;
    procedure initialiseView;
    //receives input from the game regarding changes to the state
    procedure onGameCellChangedHandler(Sender: TObject);
    function getCell(row, col: integer): TCellDisplay;
    procedure onResizeDisplay(Sender: TObject);
  protected
    //Detects key presses in the cells of the game
    //gets assigned to fOnCellKeyDown when cells are created
    procedure gameCellKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure gameCellClick(Sender:TObject);
  public
    constructor Create(aOwner: TComponent; dimensions: TPoint); reintroduce;
    procedure setGame(aGame: TNonogramGame);
    property gameCells: TCellDisplayArray read fGameCells;
  published
    property OnGameKeyDown: TKeyEvent read fOnGameKeyDown write fOnGameKeyDown;
    property OnGameClick: TNotifyEvent read fOnGameClick write fOnGameClick;
  end;

implementation

{ TCellDisplay }

constructor TCellDisplay.Create(aOwner: TComponent; cCol,cRow: integer);
begin
  inherited Create(aOwner);
  //Redirect the built in on click and key down events
  self.OnClick := @CellClickHandler;
  self.OnKeyDown := @CellKeyDownHandler;
  fPaintBox := TPaintbox.Create(aOwner);
  with fPaintBox do
  begin
    Parent := self;
    OnClick := @PaintBoxClickHandler;
    OnPaint := @DrawCell;
  end;
  fRow := cRow;
  fColumn := cCol;
end;

procedure TCellDisplay.drawCell(Sender: TObject);
var
  gameCell: TGameCell;
  game:TNonogramGame;
  oldPenColour:TColor;
begin
  if Sender is TPaintbox then
    with Sender as TPaintbox do
    begin
      //get the cell from the game corresponding to this cell
      game:=(self.Parent as TGameDisplay).fGame;
      gameCell := game.getCell(self.col, self.row);
      if (gameCell = nil) then exit;
      writeln('paint cell in row '+gameCell.row.toString+' col '+gameCell.col.toString);
      //draw the rectangle regardless
      canvas.brush.Color := gameCell.colour;
      canvas.Rectangle(0, 0, canvas.Width, canvas.Height);

      //draw focus rectangle
      if (game.selectedCell <> nil) and (game.selectedCell = gameCell) then
        begin
        oldPenColour:=canvas.Pen.Color;
        canvas.Pen.Color:=clDkGray;
        canvas.DrawFocusRect(TRect.Create(1,1,canvas.Width-1,canvas.Height-1));
        canvas.Pen.color:=oldPenColour;
        end;
    end;
end;

procedure TCellDisplay.CellClickHandler(Sender: TObject);
begin
  self.SetFocus;
  if Assigned(fOnCellClick) then fOnCellClick(self);
end;

procedure TCellDisplay.CellKeyDownHandler(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if Assigned(fOnCellKeyDown) then fOnCellKeyDown(self, key, shift);
end;

procedure TCellDisplay.PaintboxClickHandler(Sender: TObject);
begin
  self.SetFocus;
  if Assigned(fOnCellClick) then fOnCellClick(self);
end;

function TCellDisplay.getName: string;
begin
  Result := self.Name;
end;

function TCellDisplay.getRow: integer;
begin
  Result := fRow;
end;

function TCellDisplay.getCol: integer;
begin
  Result := fColumn;
end;


{ TGameDisplay }

procedure TGameDisplay.initialiseView;
var
  row,column:integer;
  thisCell: TGameCell;
  newCd: TCellDisplay;
  displayWidth, displayHeight: integer;
  cellWidth, cellHeight: integer;
begin
  if fGame = nil then exit;
  displayWidth := self.Width;
  displayHeight := self.Height;
  cellWidth := displayWidth div fGame.dimensions.X;
  cellHeight := displayHeight div fGame.dimensions.Y;
  for row := 0 to pred(fGame.dimensions.y) do
    for column:= 0 to pred(fGame.dimensions.X) do
  begin
    thisCell := fGame.block[row][column];
    newCd := TCellDisplay.Create(self, thisCell.Col, thisCell.Row);
    newCd.Parent := self;
    newCd.OnCellKeyDown := @gameCellKeyDown;
    newCd.OnCellClick:= @gameCellClick;
    newCd.Name := 'R' + thisCell.row.ToString + 'C' + thisCell.col.toString;
    newCd.Caption := '';
    newCd.Width := cellWidth;
    newCd.Height := cellHeight;
    newCd.Left := (column * cellWidth);
    newCd.Top := self.Top + (row * cellHeight);
    newCd.Visible := True;
    setLength(fGameCells, length(fGameCells) + 1);
    fGameCells[length(fGameCells) - 1] := newCd;
  end;

end;

procedure TGameDisplay.onGameCellChangedHandler(Sender: TObject);
var
  selectedCellDisplay: TCellDisplay;
begin
  //for changes signalled by the game - triggers redraw of specified cell
  if Sender is TUpdateDelegate then with Sender as TUpdateDelegate do
  begin
  selectedCellDisplay := getCell(position.Y,position.X);
  if (selectedCellDisplay <> nil)
    then selectedCellDisplay.Repaint;
  end;
end;

function TGameDisplay.getCell(row, col: integer): TCellDisplay;
var
  index: integer;
begin
  for index := 0 to pred(length(gameCells)) do
    if (gameCells[index].row = row) and (gameCells[index].col = col) then
    begin
      Result := gameCells[index];
      exit;
    end;
end;

procedure TGameDisplay.onResizeDisplay(Sender: TObject);
var
  index: integer;
  cellWidth, cellheight: integer;
begin
  //Try to keep aspect ratio
  self.Height := self.Width;
  //resize all the gameCells
  if (fGame = nil) then exit;
  cellWidth := self.Width div fGame.dimensions.X;
  cellHeight := self.Height div fGame.dimensions.Y;
  for index := 0 to pred(length(fGameCells)) do
    with fGameCells[index] do
    begin
      Width := cellWidth;
      Height := cellHeight;
      Left := ((index mod fGame.dimensions.X) * cellWidth);
      Top := (index div fGame.dimensions.Y) * cellHeight;
      repaint;
    end;
end;

procedure TGameDisplay.gameCellKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if Assigned(fOnGameKeyDown) then fOnGameKeyDown(Sender, key, shift);
end;

procedure TGameDisplay.gameCellClick(Sender: TObject);
var
  delegate:TClickDelegate;
begin
  if sender is TCellDisplay then with sender as TCellDisplay do
    begin
    delegate:=TClickDelegate.create(TPoint.Create(col,row));
    if Assigned(fOnGameClick) then fOnGameClick(delegate);
    end;
end;

constructor TGameDisplay.Create(aOwner: TComponent; dimensions: TPoint);
begin
  inherited Create(aOwner);
  Height := dimensions.Y;
  Width := dimensions.X;
  fGameCells := TCellDisplayArray.Create;
  fGame := nil;
  onResize := @onResizeDisplay;
  Name := 'myGameDisplay';
  Caption := '';
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
