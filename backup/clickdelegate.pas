unit clickDelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type
  
  { TClickDelegate }

  TClickDelegate = class(TInterfacedObject)
    private
    fPosition:TPoint;
    public
    property position:TPoint read fPosition;
    constructor create(position:TPoint);
  end;

implementation

{ TClickDelegate }

constructor TClickDelegate.create(position: TPoint);
begin
  fPosition := position;
end;

end.

