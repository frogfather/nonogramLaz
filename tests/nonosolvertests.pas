unit nonosolvertests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,nonosolver,clueCell,graphics;

type
  
  { TNgTestSolver }

  TNgTestSolver = class(TNonogramSolver)
    public
    function addToBlock(clues:TClueCells;cluesLengthBefore,clueIndex:integer):integer;
    function removeFromBlock(clues:TClueCells;cluesLengthBefore,clueIndex:integer):integer;
  end;

  TNonoSolverTests= class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AddClueToBlockTest1;
  end;

var
  ngTestSolver:TNgTestSolver;
  testClues:TClueCells;
  colour1:TColor;
  colour2:TColor;

implementation

{ TNgTestSolver }

function TNgTestSolver.addToBlock(clues:TClueCells; cluesLengthBefore, clueIndex:integer): integer;
begin
  Result:=addClueToBlock(clues,cluesLengthBefore,clueIndex);
end;

function TNgTestSolver.removeFromBlock(clues:TClueCells; cluesLengthBefore, clueIndex:integer): integer;
begin
  result:=removeClueFromBlock(clues,cluesLengthBefore,clueIndex);
end;

procedure TNonoSolverTests.AddClueToBlockTest1;
var
  newLength:integer;
begin
  testClues.push(TClueCell.create(1,-1,4,0,colour1));
  testClues.push(TClueCell.create(2,-1,1,1,colour1));
  testClues.push(TClueCell.create(3,-1,3,2,colour1));
  testClues.push(TClueCell.create(4,-1,1,3,colour1));
  newLength:=ngTestSolver.addToBlock(testClues,0,0);
  //if it isn't the last clue and the colours are the same we add 1
  AssertEquals(5,newLength);
  newLength:=ngTestSolver.addToBlock(testClues,newLength,1);
  AssertEquals(7,newLength);
  newLength:=ngTestSolver.addToBlock(testClues,newLength,2);
  AssertEquals(11,newLength);
  newLength:=ngTestSolver.addToBlock(testClues,newLength,3);
  AssertEquals(12,newLength);


end;

procedure TNonoSolverTests.SetUp;
begin
  colour1:=$00FF00;
  colour2:=$FF0000;
  ngTestSolver:=TNgTestSolver.create;
  testClues:=TClueCells.create;
end;

procedure TNonoSolverTests.TearDown;
begin

end;

initialization

  RegisterTest(TNonoSolverTests);
end.

