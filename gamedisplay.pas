unit gameDisplay;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils,controls,ExtCtrls,nonogramGame,graphics,arrayUtils,cell,
  gameDisplayInterface;

type

  { TCellDisplay }
  TCellDisplay = class(TCustomPanel,ICellDisplay)
  private
  fPaintBox:TPaintbox;
  fRow:integer;
  fColumn:integer;
  fOnCellKeyDown: TKeyEvent;
  procedure drawCell(sender:TObject);
  protected
    //intercepts onClick event of the parent object
    procedure CellClickHandler(Sender: TObject);
    //intercepts the onClick event of the paintbox
    procedure PaintboxClickHandler(Sender:TObject);
    //handles key down event in the parent object and signal the method
    //in the game if set
    procedure CellKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    property OnCellKeyDown: TKeyEvent read fOnCellKeyDown write fOnCellKeyDown;
    function getName:string;
    function getRow:integer;
    function getCol:integer;
  public
    constructor create(aOwner:TComponent; cRow,cCol:integer); reintroduce;
    property row:integer read getRow;
    property col: integer read getCol;
  end;

  { TCellDisplayArray }
  TCellDisplayArray = array of TCellDisplay;

  { TGameDisplay }

  TGameDisplay = class(TCustomPanel,IGameDisplay)
    private
      fGame:TNonogramGame;
      fCells:TCellDisplayArray;
      fOnGameKeyDown:TKeyEvent;
      procedure initialiseView;
      //receives input from the game regarding changes to the state
      procedure onGameCellChangedHandler(sender:TObject);
      function getCell(row,col:integer):TCellDisplay;
      procedure onResizeDisplay(sender:TObject);
    protected
      //Detects key presses in the cells of the game
      //gets assigned to fOnCellKeyDown when cells are created
      procedure gameCellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    public
      constructor create(aOwner:TComponent; dimensions:TPoint);reintroduce;
      procedure setGame(aGame:TNonogramGame);
      property cells:TCellDisplayArray read fCells;
    published
      property OnGameKeyDown:TKeyEvent read fOnGameKeyDown write fOnGameKeyDown;
  end;

implementation
{ TCellDisplay }

procedure TCellDisplay.drawCell(sender: TObject);
var
  sText:string;
  textLeft,textTop:integer;
  textHeight,textWidth:integer;
  edgeMarkId,centreMarkId:integer;
  gameCell:TCell;
  leftMargin,topMargin:integer;
begin
  if sender is TPaintbox then
       with sender as TPaintbox do
     begin
     //get the cell from the game corresponding to this cell
     gameCell:=(self.Parent as TGameDisplay).fGame.getCell(self.row,self.col);
     if (gameCell = nil) then exit;
     //draw the rectangle regardless
     canvas.brush.Color:=clDefault;
     canvas.Rectangle(0,0,canvas.Width,canvas.Height);
     sText:=chr(gameCell.value);
     if (gameCell.value <> -1) then
        begin
        canvas.Font.Height:= (canvas.Height * 8) div 10; //80% of box
        textHeight:=canvas.TextHeight(sText);
        textWidth:=canvas.TextWidth(sText);
        textLeft:=(canvas.Width - textWidth) div 2;
        textTop:=(canvas.Height - textHeight) div 2;
        canvas.TextOut(textLeft,textTop,sText);
        end;
     end;
end;

procedure TCellDisplay.CellClickHandler(Sender: TObject);
begin
self.SetFocus;
end;

procedure TCellDisplay.CellKeyDownHandler(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(fOnCellKeyDown) then fOnCellKeyDown(self,key,shift);
end;

procedure TCellDisplay.PaintboxClickHandler(Sender: TObject);
begin
self.SetFocus;
end;

constructor TCellDisplay.create(aOwner:TComponent;cRow,cCol:integer);
begin
  inherited create(aOwner);
  //Redirect the built in on click and key down events
  self.OnClick:=@CellClickHandler;
  self.OnKeyDown:=@CellKeyDownHandler;
  fPaintBox:=TPaintbox.Create(aOwner);
  with fPaintBox do
    begin
    Parent:=self;
    OnClick:=@PaintBoxClickHandler;
    OnPaint:=@DrawCell;
    end;
  fRow:=cRow;
  fColumn:=cCol;
end;

function TCellDisplay.getName: string;
begin
  result:= self.Name;
end;

function TCellDisplay.getRow: integer;
begin
  result:=fRow;
end;

function TCellDisplay.getCol: integer;
begin
  result:=fColumn;
end;


{ TGameDisplay }

procedure TGameDisplay.initialiseView;
var
  index,numCells:integer;
  thisCell: TCell;
  newCd: TCellDisplay;
  displayWidth,displayHeight:integer;
  cellWidth,cellHeight:integer;
begin
  if fGame = nil then exit;
  displayWidth:= self.Width;
  displayHeight:= self.Height;
  cellWidth:=displayWidth div fGame.dimensions.X;
  cellHeight:=displayHeight div fGame.dimensions.Y;
  numCells:= fGame.dimensions.X * fGame.dimensions.Y;
  for index:= 0 to pred(numCells) do
    begin
    thisCell:=fGame.cells[index];
    newCd:=TCellDisplay.Create(self, thisCell.Row, thisCell.Col);
    newCd.Parent:= self;
    newCd.OnCellKeyDown:=@gameCellKeyDown;
    newCd.Name:='R'+thisCell.row.ToString+'C'+thisCell.col.toString;
    newCd.Caption:='';
    newCd.Width:=cellWidth;
    newCd.Height:=cellHeight;
    newCd.Left:=((index mod 9) * cellWidth);
    newCd.Top:=self.Top + ((index div 9) * cellHeight);
    newCd.Visible:=true;
    setLength(fCells,length(fCells)+1);
    fCells[length(fCells) - 1]:= newCd;
    end;

end;

procedure TGameDisplay.onGameCellChangedHandler(sender: TObject);
var
  selectedCellDisplay:TCellDisplay;
begin
  //for changes signalled by the game - triggers redraw of specified cell
  if sender is TCell then
    begin
     with sender as TCell do
     begin
     selectedCellDisplay:=getCell(row,col);
     if (selectedCellDisplay <> nil) then
        selectedCellDisplay.Repaint;
     end;
    end;

end;

function TGameDisplay.getCell(row,col:integer): TCellDisplay;
var
  index:integer;
begin
  for index:=0 to pred(length(cells)) do
    if (cells[index].row = row) and (cells[index].col = col) then
       begin
       result:=cells[index];
       exit;
       end;
end;

procedure TGameDisplay.onResizeDisplay(sender:TObject);
var
  index:integer;
  cellWidth,cellheight:integer;
begin
  //Try to keep aspect ratio
  self.height:=self.Width;
  //resize all the cells
  if (fGame = nil) then exit;
  cellWidth:=self.width div fGame.dimensions.X;
  cellHeight:=self.Height div fGame.dimensions.Y;
  for index:= 0 to pred(length(fCells)) do
    with fCells[index] do
    begin
    width:= cellWidth;
    Height:= cellHeight;
    Left:=((index mod 9) * cellWidth);
    Top:=(index div 9) * cellHeight;
    repaint;
    WriteLn('w: '+cellWidth.toString+' h: '+cellHeight.ToString);
    end;
end;

procedure TGameDisplay.gameCellKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(fOnGameKeyDown) then fOnGameKeyDown(sender, key, shift);
end;

constructor TGameDisplay.create(aOwner:TComponent; dimensions: TPoint);
begin
  inherited create(aOwner);
  height:=dimensions.Y;
  width:= dimensions.X;
  fCells:=TCellDisplayArray.create;
  fGame:=nil;
  onResize:=@onResizeDisplay;
  name:='myGameDisplay';
  caption:='';
end;

procedure TGameDisplay.setGame(aGame: TNonogramGame);
begin
  fGame:=aGame;
  //assign onGameCellChangedHandler method in this class to the notify event
  //in the game
  fGame.setCellChangedHandler(@onGameCellChangedHandler);
  //assigns the notify event for a key press in this class to the handler in the game
  onGameKeyDown:=@fGame.gameInputKeyPressHandler;
  initialiseView;
end;
end.

