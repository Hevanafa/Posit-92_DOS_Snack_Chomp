{$IFDEF FPC}
library Game;
{$MODE TP}
{$ELSE}
program Game;
{$ENDIF}

{Define Release}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92KBD, P92MOUSE,
  P92BMFON, P92GRAPH, P92TEX,
  P92PANIC, P92TIME, P92VGA,
  ASSETS;

const
  FoodSpeed = 100;
  JudgementX = 64;
  MaxLives = 4;

type
  TFoodType = (
    FoodCookie,
    FoodLemon,
    FoodBomb
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

  isMouthOpen: boolean;
  lives: integer;
  invincibleEndTick: double;

  foodList: array[0..19] of TFood;
  { uses gameTime }
  nextSpawnTick: double;


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

  foodList[idx].foodType := foodType;
  foodList[idx].x := x;

  case foodType of
    FoodCookie:
      foodList[idx].texture := @texCookie;
    FoodLemon:
      foodList[idx].texture := @texLemon;

    FoodBomb: begin
      foodList[idx].texture := @texBomb;
      foodList[idx].isHarming := true;
    end;
  end;
end;

function IsInvincible: boolean;
begin
  IsInvincible := gameTime >= invincibleEndTick;
end;

{ Engine region }

{ Load assets here }
procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG\SPP92_2.BMP');

  LoadTex(texLemon, 'IMG\LEMON.BMP');
  LoadTex(texCookie, 'IMG\COOKIE.BMP');
  LoadTex(texBomb, 'IMG\BOMB.BMP');

  LoadTex(texKaylaNormal, 'IMG\KAY_NORM.BMP');
  LoadTex(texKaylaOpen, 'IMG\KAY_OPEN.BMP');

  LoadTex(texHeartEmpty, 'IMG\HRTEMPTY.BMP');
  LoadTex(texHeartFill, 'IMG\HRTFILL.BMP');

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

  lives := MaxLives;
  invincibleEndTick := 0.0;

  fillchar(foodList, sizeof(foodList), 0);

  isMouthOpen := true;

  nextSpawnTick := 2.0;
end;

{ Handle game state updates here }
procedure Update; far;
var
  a: integer;
begin
  { Handle inputs }

{$ifndef release}
  if IsKeyDown(SC_ESCAPE) then SignalDone;
{$else}
  if IsKeyDown(SC_LEFT_SHIFT) and IsKeyDown(SC_Q) then SignalDone;
{$endif}

  isMouthOpen := not IsKeyDown(SC_SPACE);

  { Handle gameplay state }

  for a:=0 to high(foodList) do begin
    if not foodList[a].active then continue;

    foodList[a].x := foodList[a].x - FoodSpeed * DeltaTime;

    if foodList[a].x < JudgementX then begin
      { case foodList[a].foodType of
      end; }

      if foodList[a].isHarming then begin
        { Eat harming food }

        if isMouthOpen and (not IsInvincible) then begin
          invincibleEndTick := gameTime + 3.0;
          dec(lives)
        end;

        foodList[a].active := false;
        continue
      end;

      if isMouthOpen then begin
        { Eat food }
        inc(score, 100);
      end;

      foodList[a].active := false;

      continue
    end;
  end;

  if gameTime >= nextSpawnTick then begin
    nextSpawnTick := gameTime + 0.5;

    SpawnFood(
      TFoodType(random(ord(high(TFoodType)) + 1)),
      VGAWidth + 10);
  end;

  gameTime := gameTime + DeltaTime
end;

{ Render logic }
procedure Draw; far;
var
  a: integer;
begin
  Cls($4F);

  { spr(texLemon, 10, 10);
  spr(texCookie, 40, 10); }

  for a:=0 to high(foodList) do begin
    if not foodList[a].active then continue;

    VLine(trunc(foodList[a].x), 68, 132, $0F);

    spr(foodList[a].texture^,
      trunc(foodList[a].x - foodList[a].texture^.width / 2),
      100)
  end;

  if isMouthOpen then
    spr(texKaylaOpen, 32, 68)
  else
    spr(texKaylaNormal, 32, 68);

  VLine(JudgementX, 68, 132, $0F);

  { HUD stuff }

  for a:=0 to MaxLives - 1 do
    spr(texHeartEmpty, 160 + a * 20, 8);

  if lives > 0 then
    for a:=0 to lives - 1 do
      spr(texHeartFill, 160 + a * 20, 8);

  PrintDefault(i32str(score), 8, 8);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableDrawFPS := true;
  appConfig.WaitMode := P92WaitVSync;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
