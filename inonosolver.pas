unit iNonoSolver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,gameState;
type
  INonogramSolver = interface
  ['{4b1ccfe5-4335-49c9-b915-4ac796d66ab5}']
  function solve(initialState:TGameState):TGameState;
  end;

implementation

end.

