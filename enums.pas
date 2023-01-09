unit enums;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type
  { EInputMode }
  EInputMode = (imFill, imCross, imDot);
  { ECellFillMode }
  ECellFillMode = (cfEmpty,cfFill,cfCross,cfDot);
  { EGameMode }
  EGameMode = (gmSet, gmSolve);
  { ECellType }
  ECellType = (ctGame,ctClue);

implementation

end.

