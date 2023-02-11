unit nonoForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  nonogramGame, gameDisplay;

type

  { TfNonogram }

  TfNonogram = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
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
  gameDisplay_:=TGameDisplay.create(self,TPoint.create(self.Width,self.Height));
  gameDisplay_.Parent:=self;
  gameDisplay_.Top:=20;
  gameDisplay_.Left:=30;
  gameDisplay_.Anchors:=[akRight,akBottom,akLeft,akTop];
  gameDisplay_.Color:=clDefault;
  gameDisplay_.Visible:=true;
  gameDisplay_.Caption:='';
  //gameDisplay_.setGame(createSampleGame);
end;

function TfNonogram.createSampleGame: TNonogramGame;
begin
  //result:=TNonogramGame.create('test',TPoint.Create(20,20));
  result:=TNonogramGame.create('/Users/cloudsoft/Downloads/test.txt');
end;

end.

