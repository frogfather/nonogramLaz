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
    procedure FormDestroy(Sender: TObject);
  private

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
end;

procedure TfNonogram.FormDestroy(Sender: TObject);
begin
  writeln('call destroy form');
end;



end.

