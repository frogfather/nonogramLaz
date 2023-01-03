unit gameDisplayInterface;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,controls;
type
  { INonogramGame }
  INonogramGame = interface
  ['{2ad6d14d-bb5d-4a9a-9ea7-0887852e586a}']
  procedure gameInputKeyPressHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure saveToFile(filename:string);
  procedure start;
  procedure reset;
  end;

  { ICellDisplay }
  ICellDisplay = interface
  ['{706a72da-db9c-413a-a9a6-2a0606f10bd1}']
  function getName:string;
  function getRow:integer;
  function getCol:integer;
  function getBox:integer;
  end;

  { IGameDisplay }
  IGameDisplay = interface
  ['{35f635d4-4b48-4dcd-906d-2950f4057a39}']
  procedure gameCellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;


implementation

end.

