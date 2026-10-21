unit Assets;

interface

uses P92BMFON, P92TEX;

var
  fontP92SansBold: TBMFont;

  texSpecimenP92: array[0..1] of TTexture;
  texLemon, texCookie, texBomb: TTexture;
  texKaylaNormal, texKaylaOpen: TTexture;

procedure PrintDefault(const text: string; const x, y: integer);


implementation

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(fontP92SansBold, text, x, y)
end;

end.

