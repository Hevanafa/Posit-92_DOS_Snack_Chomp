unit Assets;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92BMFON, P92TEX, P92SPKR;

var
  fontP92SansBold, fontP92SansBoldBlack,
  fontX14y20pxScoreDozer: TBMFont;

  texSpecimenP92: array[0..1] of TTexture;

  texPipe, texGooWipe,
  texLemon, texCookie, texBomb,
  texKaylaNormal, texKaylaOpen, texKaylaPortrait,
  texHeartFill, texHeartEmpty: TTexture;

  sfxChomp: TMelody;

procedure PrintDefault(const text: string; const x, y: integer);
function MeasureDefault(const text: string): integer;
procedure PrintBlack(const text: string; const x, y: integer);

procedure PrintScoreDozer(const text: string; const x, y: integer);
function MeasureScoreDozer(const text: string): integer;


implementation

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(fontP92SansBold, text, x, y)
end;

function MeasureDefault(const text: string): integer;
begin
  MeasureDefault := MeasureBMFont(fontP92SansBold, text)
end;

procedure PrintBlack(const text: string; const x, y: integer);
begin
  PrintBMFont(fontP92SansBoldBlack, text, x, y);
end;

procedure PrintScoreDozer(const text: string; const x, y: integer);
begin
  PrintBMFont(fontX14y20pxScoreDozer, text, x, y)
end;

function MeasureScoreDozer(const text:string):integer;
begin
  MeasureScoreDozer := MeasureBMFont(fontX14y20pxScoreDozer, text);
end;


end.

