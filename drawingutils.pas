unit drawingUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,Graphics,ExtCtrls,FPCanvas;

function inBounds(canvas_:TCanvas;rect_:TRect):boolean;
procedure drawFrame(canvas_:TCanvas;rect_:TRect;colour:TColor=clBlack;style_:TFPPenStyle=psSolid);
implementation

function inBounds(canvas_:TCanvas;rect_: TRect): boolean;
begin
  result:= (Rect_.Left >= 0)and(rect_.Right <= canvas_.Width)
  and (rect_.Top >= 0)and(rect_.Bottom <= canvas_.height);
end;


procedure drawFrame(canvas_: TCanvas; rect_: TRect; colour: TColor;
  style_: TFPPenStyle);
begin
  if not inBounds(canvas_,rect_) then exit;
  with canvas_ do
    begin
    pen.Color:=colour;
    pen.Style:=style_;
    MoveTo(rect_.TopLeft);
    lineTo(rect_.Left,rect_.Bottom);
    lineTo(rect_.BottomRight);
    lineTo(rect_.Right,rect_.Top);
    lineTo(rect_.TopLeft);
    end;
end;

end.

