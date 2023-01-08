unit updateDelegate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;
type

  { TUpdateDelegate }
  //Modify to allow multiple cells
  TUpdateDelegate = class(TInterfacedObject)
    private
    fPosition:TPoint;//which cell to update
    public
    property position:TPoint read fPosition;
    constructor create(position_:TPoint);
  end;
implementation

{ TUpdateDelegate }

constructor TUpdateDelegate.create(position_: TPoint);
begin
  fPosition:=position_;
end;

end.

