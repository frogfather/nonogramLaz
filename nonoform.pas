unit nonoForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,nonogramGame,gameDisplay,cell;

type

  { TfNonogram }

  TfNonogram = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    fOnModeSwitchInput: TKeyEvent; //gets assigned to the modeSwitchKeyPressHandler of the game
    function createSampleGame:TNonogramGame;
  public

  end;

var
  fNonogram: TfNonogram;
  gameDisplay_:TGameDisplay;
implementation

{$R *.lfm}

{ TfNonogram }

procedure TfNonogram.FormCreate(Sender: TObject);
begin
  gameDisplay_:=TGameDisplay.create(self,TPoint.create(500,500));
  gameDisplay_.Parent:=self;
  gameDisplay_.Top:=20;
  gameDisplay_.Left:=30;
  gameDisplay_.Anchors:=[akRight,akBottom,akLeft,akTop];
  gameDisplay_.Color:=clDefault;
  gameDisplay_.Visible:=true;
  gameDisplay_.Caption:='';
  gameDisplay_.setGame(createSampleGame);
end;

function TfNonogram.createSampleGame: TNonogramGame;
begin
  result:=TNonogramGame.create('test',TPoint.Create(10,10));
end;

end.

