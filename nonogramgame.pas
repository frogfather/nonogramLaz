unit nonogramGame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type
  
  { TNonogramGame }

  TNonogramGame = class(TinterfacedObject)
    private
    public
    constructor create(filename:string);
  end;

implementation

{ TNonogramGame }

constructor TNonogramGame.create(filename: string);
begin
  //loadfrom file
end;

end.

