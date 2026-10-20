program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

{Define Release}

uses
  CRT, DOS,
  P92CORE, P92BMFON, P92KBD, P92MOUSE, P92TEX,
  P92PANIC, P92TIME, P92VGA,
  ASSETS;

const
  FoodSpeed = 100;

type
  TFoodType = (
    FoodCookie,
    FoodLemon
  );

  TFood = record
    active: boolean;
    foodType: TFoodType;
    x: double;
    texture: PTexture;
    isHarming: boolean;
  end;

var
  { Game state variables }
  gameTime: double;
  score: longint;

  foodList: array[0..19] of TFood;


procedure SpawnFood(const foodType: TFoodType; const x: double);
var
  a, idx: integer;
begin
  idx := -1;

  for a:=0 to high(foodList) do
    if not foodList[a].active then begin
      idx := a;
      break
    end;

  if idx < 0 then PanicHalt('SpawnFood: Food list is full!');

  FillChar(foodList[idx], sizeof(TFood), 0);

  foodList[idx].active := true;

  { TODO: Init food item }

end;

{ Engine region }

{ Load assets here }
procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG\SPP92_2.BMP');

  LoadTex(texLemon, 'IMG\LEMON.BMP');
  LoadTex(texCookie, 'IMG\COOKIE.BMP');

  LoadBMFont(fontP92SansBold, 'FONTS\P92SAN8B.TXT');
end;

{ Free all the resources here }
procedure OnCleanup; far;
begin
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);
end;

{ Init game state variables here }
procedure OnReady; far;
begin
  gameTime := 0.0;
  score := 0;

  fillchar(foodList, sizeof(foodList), 0);
end;

{ Handle game state updates here }
procedure Update; far;
begin
{$ifndef release}
  if IsKeyDown(SC_ESCAPE) then SignalDone;
{$else}
  if IsKeyDown(SC_LEFT_SHIFT) and IsKeyDown(SC_Q) then SignalDone;
{$endif}

  gameTime := gameTime + DeltaTime
end;

{ Render logic }
procedure Draw; far;
begin
  Cls($4F);

  spr(texLemon, 10, 10);
  spr(texCookie, 40, 10);

  if frac(gameTime * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  PrintDefault('Hello world!', 160-48, 120);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
