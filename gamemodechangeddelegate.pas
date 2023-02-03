unit gamemodechangeddelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,enums;
type

{ TGameModeChangedDelegate }

TGameModeChangedDelegate = class(TInterfacedObject)
    private
    fGameMode: EGameMode;
    public
    constructor create(gameMode_:EGameMode);
    property gameMode:EGameMode read fGameMode;
  end;

implementation

{ TGameStateChangedDelegate }

constructor TGameModeChangedDelegate.create(gameMode_: EGameMode);
begin
  fGameMode:=gameMode_;
end;

end.

