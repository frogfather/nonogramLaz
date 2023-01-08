unit clickDelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,arrayUtils;
type
  
  { TClickDelegate }
  //Should allow multiple cells
  TClickDelegate = class(TInterfacedObject)
    private
    fSelectedCells:TPointArray;
    public
    property selectedCells:TPointArray read fSelectedCells;
    constructor create(cells_:TPointArray);
  end;

implementation

{ TClickDelegate }

constructor TClickDelegate.create(cells_: TPointArray);
begin
  fSelectedCells := cells_;
end;

end.

