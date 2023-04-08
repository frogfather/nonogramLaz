unit clueOptionTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,clueOption,enums,graphics;

type

  { clueOptionEntryTests }

  clueOptionEntryTests= class(TTestCase)
  private
    fClueOptionEntry: TClueOptionEntry;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure moveToStartWhenExists(index:integer);
    procedure moveToStartDoesNothingIfIndexOutOfRange(index:integer);
  end;

implementation

procedure clueOptionEntryTests.SetUp;
var
  id:integer;
begin
  fClueOptionEntry:=TClueOptionEntry.create;
  //add 20 clue options
  for id:=0 to 5 do
    fClueOptionEntry.push(TClueOption.create(clBlack,cfFill,0));
  fClueOptionEntry.push(TClueOption.create(clBlack,cfCross,-1));
  for id:=0 to 3 do
    fClueOptionEntry.push(TClueOption.create(clBlack,cfFill,1));
  fClueOptionEntry.push(TClueOption.create(clBlack,cfEmpty,-1));
  fClueOptionEntry.push(TClueOption.create(clBlack,cfCross,-1));
  for id:=0 to 6 do
    fClueOptionEntry.push(TClueOption.create(clBlack,cfEmpty,-1));
end;

procedure clueOptionEntryTests.TearDown;
begin
  inherited TearDown;
end;

procedure clueOptionEntryTests.moveToStartWhenExists(index: integer);
var
  moveResult:boolean;
begin
  AssertEquals(20,fClueOptionEntry.size);
  AssertTrue(fClueOptionEntry[0].fill = cfFill);
  AssertTrue(fClueOptionEntry[12].fill = cfCross);
  moveResult:=fClueOptionEntry.moveToStart(11);
  AssertTrue(moveResult);
  AssertTrue(fClueOptionEntry[0].fill = cfEmpty);
  AssertTrue(fClueOptionEntry[12].fill = cfCross);
end;

procedure clueOptionEntryTests.moveToStartDoesNothingIfIndexOutOfRange(
  index: integer);
var
  moveResult:boolean;
begin
  moveResult:=fClueOptionEntry.moveToStart(20);
  AssertFalse(moveResult);
  moveResult:=fClueOptionEntry.moveToStart(-1);
  AssertFalse(moveResult);
end;




initialization

  RegisterTest(clueOptionEntryTests);
end.

