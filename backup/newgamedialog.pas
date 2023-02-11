unit newgamedialog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, MaskEdit, ComCtrls,
  StdCtrls;

type

  { TfNewGameDialog }

  TfNewGameDialog = class(TForm)
    bCreate: TButton;
    eName: TEdit;
    lName: TLabel;
    lHeight: TLabel;
    lWidth: TLabel;
    meWidth: TMaskEdit;
    meHeight: TMaskEdit;
    udWidth: TUpDown;
    udHeight: TUpDown;
    procedure eNameChange(Sender: TObject);
  private
    function asInteger(input:string):integer;
  public

  end;

var
  fNewGameDialog: TfNewGameDialog;

implementation

{$R *.lfm}

{ TfNewGameDialog }

procedure TfNewGameDialog.eNameChange(Sender: TObject);
begin
   bCreate.enabled:= (eName.Text <> '')
    and (asInteger(meWidth.Text) <> 0)
    and(asInteger(meHeight.Text) <> 0);
end;

//turn the output of the mask edits to integers
function TfNewGameDialog.asInteger(input: string): integer;
begin
  result:=0;
  if input[1]='0' then exit;
  if input[2]<>'_'
    then result:=input.Trim.ToInteger else result:=input.Substring(0,1).trim.ToInteger;
end;

end.

