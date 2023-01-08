unit arrayUtils;

{$mode objfpc}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils, graphics,fgl;
type
  generic Tarray<T> = array of T;
  generic TCompareFunc<T> = function (const elem1, elem2:T): integer;

  TIntArray = array of integer;
  TInt64Array = array of int64;
  TStringMap = specialize TFPGMap<String,String>;
  TStringIntMap = specialize TFPGMap<String,Integer>;
  TStringInt64Map = specialize TFPGMap<String,Int64>;
  T2DIntMap = array of array of integer;
  T3DIntMap = array of array of array of integer;
  T2DStringArray = array of array of string;
  TColours = array of TColor;
  TPointArray = array of TPoint;

  { TIntArrayHelper }

  TIntArrayHelper = type helper for TIntArray
  function size: integer;
  function push(element:integer):integer;
  function indexOf(element:integer):integer;
  function splice(index:integer; deleteCount:integer=0; newItems: TIntArray=nil):TIntArray;
  function sort(ascending:Boolean=true):TIntArray;
  function toCSV: string;
  end;

  { TInt64ArrayHelper }

  TInt64ArrayHelper = type helper for TInt64Array
  function size: integer;
  function push(element:int64):integer;
  function indexOf(element:int64):integer;
  function splice(index:integer; deleteCount:integer=0;newItems: TInt64Array=nil):TInt64Array;
  function sort(ascending:Boolean=true):TInt64Array;
  end;

  { TStringArrayHelper }
  TStringArrayHelper = type helper for TStringArray
  function size: integer;
  function push(element: string):integer;
  function indexOf(element:string):integer;
  function splice(index:integer; deleteCount: integer=0; newItems: TStringArray=nil):TStringArray;
  function sort(ascending:Boolean=true):TStringArray;
  function toIntArray:TIntArray;
  end;

  { TCharArrayHelper }
  TCharArrayHelper = type helper for TCharArray
  function size: integer;
  function push(element: char): integer;
  function indexOf(element:char):integer;
  function splice(index:integer; deleteCount: integer=0; newItems: TCharArray=nil):TCharArray;
  function sort(ascending:Boolean=true):TCharArray;
  end;
  { TPointArrayHelper }
  TPointArrayHelper = type helper for TPointArray
  function size: integer;
  function push(element: TPoint):integer;
  function indexOf(element:TPoint):integer;
  function splice(index:integer; deleteCount: integer=0; newItems: TPointArray=nil):TPointArray;
  end;


function containsCharacters(toSearch,toFind:String):boolean;
function CSVToIntArray(input:string):TIntArray;

generic procedure gSort<T>(var arr: specialize TArray<T>; CompareFunc: specialize TCompareFunc<T>;idxL,idxH:integer;
  swapBuffer,medBuffer: T);

implementation

{ generic methods for use by helpers }
generic procedure genericSort<T>(
        var aArr: specialize TArray<T>;
        comparatorAsc, comparatorDesc: specialize TCompareFunc<T>;
        ascending:boolean=true);
var
  comparator: specialize TCompareFunc<T>;
  swapBuf,medBuf: T;
begin
  if ascending then comparator:= comparatorAsc else comparator:= comparatorDesc;
  specialize gSort<T>(aArr, comparator, 0, pred(length(aArr)),swapBuf,medBuf)
end;

generic procedure gSort<T>(var arr: specialize TArray<T>;
  CompareFunc: specialize TCompareFunc<T>;
  idxL,idxH:integer;
  swapBuffer,medBuffer: T);
var
  li,hi : Integer; //index
  mi    : Integer; //middle index: low + high div 2
begin
  li:=idxL;
  hi:=idxH;
  mi:=(li+hi) div 2;
  medBuffer:=arr[mi];
  repeat
    while CompareFunc( arr[li], medBuffer) < 0 do inc(li);
    while CompareFunc( medBuffer, arr[hi] ) < 0 do dec(hi);
    if li <= hi then
      begin
      swapBuffer:= arr[li];
      arr[li]:=arr[hi];
      arr[hi]:=swapBuffer;
      inc(li);
      dec(hi);
    end;
  until li>hi;
  if hi>idxL then specialize gSort<T>(Arr, CompareFunc, idxL, hi, SwapBuffer, MedBuffer);
  if li<idxH then specialize gSort<T>(Arr, CompareFunc, li, idxH, SwapBuffer, MedBuffer);
end;

generic function GetIndex<T>(aItem:T; aArr: specialize TArray<T>): SizeInt;
begin
  for Result := 0 to High(aArr) do
    if aArr[Result] = aItem then
      Exit;
  Result := -1;
end;

generic function splice<T>(var aArray: specialize TArray<T>; index, deleteCount: sizeInt; var newItems: specialize TArray<T>
  ): specialize TArray<T>;
var
  normalizedCount, normalizedIndex, adjustIndex:sizeInt;
begin
 result:= specialize TArray<T>.create;
 //if index is greater than or equal to the size of the array then adjust it
  if (index > high(aArray)) then normalizedIndex:= high(aArray)
    else normalizedIndex:= index;
  //TODO - if index is negative should start at end of array

  //if the delete normalizedCount would take us off the end of the array then adjust it
  if (deleteCount > high(aArray) - normalizedIndex) then
    normalizedCount:= high(aArray) - normalizedIndex
      else normalizedCount:= deleteCount;

   if(deleteCount > 0) then
     begin
     //add the items that are to be deleted to the result array
     for adjustIndex:=normalizedIndex to normalizedIndex + pred(normalizedCount) do
       insert(aArray[adjustIndex],result,length(result));
     for adjustIndex:= normalizedIndex to pred(length(aArray) - normalizedCount) do
       aArray[adjustIndex]:= aArray[adjustIndex + normalizedCount];
     setLength(aArray, length(aArray) - normalizedCount);
     end;

   if (newItems <> nil) then
     begin
     setLength(aArray, length(aArray) + length(newItems));

     for adjustIndex:= high(aArray) downTo normalizedIndex + 1 do
       aArray[adjustIndex]:= aArray[adjustIndex - length(newItems)];

     for adjustIndex:= 0 to high(newItems) do
       aArray[index+adjustIndex]:= newItems[adjustIndex];
     end;
end;

//TODO Use ascii values instead of this
const strChars: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

function removeBlankEntriesFromArray(arrInput: TStringArray): TStringArray;
var
  index: integer;
begin
  index:=length(arrInput);
  for index:= pred(length(arrInput)) downto 0 do
    begin
      if (length(arrInput[index]) = 0) then
        arrInput.splice(index,1);
    end;
  result:=arrInput;
end;

function containsCharacters(toSearch, toFind: String): boolean;
var
  index:integer;
  thisChar:string;
begin
  result:=true;
  for index:=1 to length(toFind)do
    begin
      thisChar:=tofind[index];
      if not toSearch.Contains(thisChar) then
        begin
        result:=false;
        exit;
        end;
    end;
end;

{ Comparer functions for sort methods }
function CompareInt64Asc(const i1,i2: int64): integer;
begin
  if i1=i2 then Result:=0
  else if i1<i2 then Result:=-1
  else Result:=1;
end;
function CompareInt64Desc(const i1,i2: int64): integer;
begin
  if i1=i2 then Result:=0
  else if i1>i2 then Result:=-1
  else Result:=1;
end;

function CompareIntAsc(const i1,i2: integer): integer;
begin
  if i1=i2 then Result:=0
  else if i1<i2 then Result:=-1
  else Result:=1;
end;

function CompareIntDesc(const i1,i2: integer): integer;
begin
  if i1=i2 then Result:=0
  else if i1>i2 then Result:=-1
  else Result:=1;
end;

function CompareStrAsc(const s1,s2: string): integer;
var
  shortestStringLength,strIndex:integer;
  comparison:integer;
  done:boolean;
begin
  shortestStringLength:=length(s1);
  if (length(s2)<length(s1))then shortestStringLength:=length(s2);
  strIndex:=0;
    repeat
    comparison:= strChars.IndexOf(s2.Substring(strIndex,1))
    - strChars.indexOf(s1.Substring(strIndex,1));
    strIndex:=strIndex+1;
    done:=(strIndex > pred(shortestStringLength)) or (comparison <> 0);
    until done;
    if (comparison = 0)then result:=0
      else result:=comparison div abs(comparison);
end;

function CompareStrDesc(const s1,s2: string): integer;
var
  shortestStringLength,strIndex:integer;
  comparison:integer;
  done:boolean;
begin
  shortestStringLength:=length(s1);
  if (length(s2)<length(s1))then shortestStringLength:=length(s2);
  strIndex:=0;
    repeat
    comparison:= strChars.IndexOf(s1.Substring(strIndex,1))
    - strChars.indexOf(s2.Substring(strIndex,1));
    strIndex:=strIndex+1;
    done:=(strIndex > pred(shortestStringLength)) or (comparison <> 0);
    until done;
    if (comparison = 0)then result:=0
      else result:=comparison div abs(comparison);
end;

function CompareCharAsc(const s1,s2: char): integer;
var
  comparison:integer;
begin
  comparison:= strChars.IndexOf(s1) - strChars.indexOf(s2);
  if (comparison = 0)then result:=0
    else result:=comparison div abs(comparison);
end;

function CompareCharDesc(const s1,s2: char): integer;
var
  comparison:integer;
begin
  comparison:= strChars.IndexOf(s2) - strChars.indexOf(s1);
  if (comparison = 0)then result:=0
    else result:=comparison div abs(comparison);
end;

function CSVToIntArray(input: string): TIntArray;
var
  strArray:TStringArray;
  output:TIntArray;
  index:integer;
begin
  //should check these are integers
  result:=nil;
  if pos(',',input) > 0 then
    begin
    strArray:=input.Split(',');
    output:=TIntArray.create;
    setLength(output,length(strArray));
    for index:=0 to pred(length(strArray)) do
      output[index]:= strArray[index].ToInteger;
    result:=output;
    end;
end;

{ TCharArrayHelper }

function TCharArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TCharArrayHelper.push(element: char): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TCharArrayHelper.indexOf(element: char): integer;
begin
  result:= specialize getIndex<char>(element,self);
end;

function TCharArrayHelper.splice(index: integer; deleteCount: integer;
  newItems: TCharArray): TCharArray;
begin
  result:= specialize splice<char>(self,index,deleteCount, newItems);
end;

function TCharArrayHelper.sort(ascending: Boolean): TCharArray;
begin
  specialize genericSort<char>(self, @CompareCharAsc, @CompareCharDesc, ascending);
  result:=self;
end;

{ TStringArrayHelper }

function TStringArrayHelper.size: integer;
begin
  result:= length(self);
end;

function TStringArrayHelper.push(element: string): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TStringArrayHelper.indexOf(element: string): integer;
begin
  result:= specialize getIndex<string>(element,self);
end;

function TStringArrayHelper.splice(index: integer; deleteCount: integer;
  newItems: TStringArray): TStringArray;
begin
  result:= specialize splice<string>(self,index,deleteCount, newItems);
end;

function TStringArrayHelper.sort(ascending: Boolean): TStringArray;
begin
  specialize genericSort<string>(self, @CompareStrAsc, @CompareStrDesc, ascending);
  result:=self;
end;

function TStringArrayHelper.toIntArray: TIntArray;
var
  index:integer;
begin
  result:=TIntArray.create;
  setLength(result,length(self));
  if length(self) = 0 then exit;
  for index:=0 to pred(length(self)) do
    begin
      try
      result[index]:=strToInt(self[index]);
      except
      //do nothing atm
      end;
    end;
end;

{ TInt64ArrayHelper }
function TInt64ArrayHelper.size: integer;
begin
  result:= length(self);
end;

function TInt64ArrayHelper.push(element: int64): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TInt64ArrayHelper.indexOf(element: int64): integer;
begin
  result:= specialize getIndex<int64>(element,self);
end;

function TInt64ArrayHelper.splice(index: integer; deleteCount: integer;
  newItems: TInt64Array): TInt64Array;
begin
  result:= specialize splice<int64>(self,index,deleteCount,newItems);
end;

function TInt64ArrayHelper.sort(ascending: Boolean): TInt64Array;
begin
  specialize genericSort<Int64>(self, @CompareInt64Asc, @CompareInt64Desc, ascending);
  result:=self;
end;

{ TIntArrayHelper }
function TIntArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TIntArrayHelper.push(element: integer): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TIntArrayHelper.indexOf(element: integer): integer;
begin
  result:= specialize getIndex<integer>(element,self);
end;

function TIntArrayHelper.splice(index: integer; deleteCount: integer;
  newItems: TIntArray): TIntArray;
begin
 result:= specialize splice<integer>(self,index,deleteCount,newItems);
end;

function TIntArrayHelper.sort(ascending: Boolean):TIntArray;
begin
  specialize genericSort<Integer>(self, @CompareIntAsc,@CompareIntDesc, ascending);
  result:=self;
end;

function TIntArrayHelper.toCSV: string;
var
  index:integer;
  output:string;
begin
  output:='';
  for index:= 0 to pred(length(self)) do
    begin
    output:=output+self[index].ToString;
    if index < pred(length(self)) then
      output:=output + ',';
    end;
  result:=output;
end;
{ TPointArrayHelper }

function TPointArrayHelper.size: integer;
begin
  result:=length(self);
end;

function TPointArrayHelper.push(element: TPoint): integer;
begin
  insert(element,self,length(self));
  result:=self.size;
end;

function TPointArrayHelper.indexOf(element: TPoint): integer;
begin
  result:= specialize getIndex<TPoint>(element,self);
end;

function TPointArrayHelper.splice(index: integer; deleteCount: integer;
  newItems: TPointArray): TPointArray;
begin
  result:= specialize splice<TPoint>(self,index,deleteCount,newItems);
end;


end.

