unit gameStateChangedDelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,enums;
type

{ TGameStateChangedDelegate }

TGameStateChangedDelegate = class(TInterfacedObject)
    private
    fGameState: EGameMode;
    public
    constructor create(gameMode_:EGameMode);
    property gameState:EGameMode read fGameState;
  end;

implementation

{ TGameStateChangedDelegate }

constructor TGameStateChangedDelegate.create(gameMode_: EGameMode);
begin
  fGameState:=gameMode_;
end;

end.

