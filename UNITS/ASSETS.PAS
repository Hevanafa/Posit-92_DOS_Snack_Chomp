unit Assets;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92BMFON, P92TEX;

var
  fontP92SansBold: TBMFont;

  texSpecimenP92: array[0..1] of TTexture;

  texPipe,
  texLemon, texCookie, texBomb,

  texKaylaNormal, texKaylaOpen,

  texHeartFill, texHeartEmpty: TTexture;

procedure PrintDefault(const text: string; const x, y: integer);
function MeasureDefault(const text: string): integer;


implementation

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(fontP92SansBold, text, x, y)
end;

function MeasureDefault(const text: string): integer;
begin
  MeasureDefault := MeasureBMFont(fontP92SansBold, text)
end;

end.

