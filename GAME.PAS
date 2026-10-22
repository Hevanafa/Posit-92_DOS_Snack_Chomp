{$IFDEF FPC}
library Game;
{$MODE TP}
{$ELSE}
program Game;
{$ENDIF}

{Define Release}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92GEOM, P92KBD, P92MOUSE,
  P92BMFON, P92GRAPH, P92TEX,
  P92PANIC, P92TIME, P92VGA,
  ASSETS;

const
  TwoPi = 2 * Pi;

  { in seconds }
  InvincibleDuration = 3.0;
  FoodSpawnRate = 1.25;
  FoodSpeed = 80;

  JudgementX = 64;
  MaxLives = 4;

type
  TGameState = (
    GameStateTitle,
    GameStatePlaying,
    GameStateOver
  );

  { 2D vector }
  TVector = TPoint;

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

  TFloatingText = record
    active: boolean;
    text: string;
    endTick: double;
    pos: TPoint;
    vel: TVector;
  end;


var
  { Game state variables }
  actualGameState: TGameState;

  countdownNumber: integer;
  { uses real time }
  countdownNextTick: double;

  { Only applies in the playing state }
  gameTime: double;
  score: longint;
  { fullness: double; }

  isMouthOpen: boolean;
  lives: integer;
  { uses gameTime }
  invincibleEndTick: double;
  isBlinkingVisible: boolean;

  foodList: array[0..19] of TFood;
  { uses gameTime }
  nextSpawnTick: double;

  floatingTexts: array[0..9] of TFloatingText;


procedure InitTitleState;
begin
  actualGameState := GameStateTitle;
end;

procedure ResetGameplayState;
begin
  RandSeed := trunc(GetTimer);

  gameTime := 0.0;
  score := 0;
  lives := MaxLives;
  invincibleEndTick := 0.0;

  fillchar(foodList, sizeof(foodList), 0);
  fillchar(floatingTexts, sizeof(floatingTexts), 0);

  isBlinkingVisible := true;
  isMouthOpen := false;

  nextSpawnTick := 2.0;
end;

procedure InitPlayingState;
begin
  actualGameState := GameStatePlaying;

  countdownNumber := 3;
  countdownNextTick := GetTimer + 1.0;
end;

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
  IsInvincible := gameTime < invincibleEndTick;
end;

procedure SpawnFloatingText(const text: string; const x, y: double);
var
  a, idx: integer;
begin
  idx := -1;

  for a:=0 to high(floatingTexts) do
    if not floatingTexts[a].active then begin
      idx := a;
      break
    end;

  if idx < 0 then PanicHalt('Floating text pool is full!');

  fillchar(floatingTexts[idx], sizeof(TFloatingText), 0);

  floatingTexts[idx].active := true;
  floatingTexts[idx].text := text;
  floatingTexts[idx].pos.x := x;
  floatingTexts[idx].pos.y := y;
  floatingTexts[idx].vel.y := -15.0;
  floatingTexts[idx].endTick := gameTime + 2.0;
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
  actualGameState := GameStateTitle;

  InitTitleState;
  ResetGameplayState;
end;

{ Handle game state updates here }
procedure Update; far;
var
  now: double;
  a: integer;
begin
  now := GetTimer;

  { Handle inputs }

{$ifndef release}
  if IsKeyDown(SC_ESCAPE) then SignalDone;
{$else}
  if IsKeyDown(SC_LEFT_SHIFT) and IsKeyDown(SC_Q) then SignalDone;
{$endif}

  if actualGameState = GameStateTitle then begin
    if IsKeyDown(SC_SPACE) then
      InitPlayingState;
  end;


  if actualGameState = GameStatePlaying then begin
    { Handle inputs }

    isMouthOpen := not IsKeyDown(SC_SPACE);
    isBlinkingVisible := not isBlinkingVisible;

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
            invincibleEndTick := gameTime + InvincibleDuration;
            dec(lives)
          end;

          foodList[a].active := false;
          continue
        end;

        if isMouthOpen then begin
          { Eat food }
          inc(score, 100);
          SpawnFloatingText('+100', JudgementX, 100);
        end;

        foodList[a].active := false;

        continue
      end;
    end;

    if gameTime >= nextSpawnTick then begin
      nextSpawnTick := gameTime + 1 / FoodSpawnRate;

      SpawnFood(
        TFoodType(random(ord(high(TFoodType)) + 1)),
        VGAWidth + 10);
    end;

    for a:=0 to high(floatingTexts) do begin
      if not floatingTexts[a].active then continue;

      if gameTime >= floatingTexts[a].endTick then begin
        floatingTexts[a].active := false;
        continue
      end;

      floatingTexts[a].pos.y := floatingTexts[a].pos.y + floatingTexts[a].vel.y * DeltaTime;
      floatingTexts[a].pos.x := floatingTexts[a].pos.x + floatingTexts[a].vel.x * DeltaTime;
    end;

    if countdownNumber > 0 then begin
      if now >= countdownNextTick then begin
        countdownNextTick := now + 1.0;
        dec(countdownNumber);
      end;
    end else
      gameTime := gameTime + DeltaTime;
  end;
end;

{ Render logic }
procedure Draw; far;
var
  a: integer;
  w: integer;
  s: string;
  colour: byte;
  now: double;
begin
  now := GetTimer;

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

  if not IsInvincible or (isBlinkingVisible and IsInvincible) then begin
    if isMouthOpen then
      spr(texKaylaOpen, 32, 68)
    else
      spr(texKaylaNormal, 32, 68);
  end;

{$ifndef release}
  { VLine(JudgementX, 68, 132, $0F); }
{$endif}

  { HUD & overlay stuff }

  if actualGameState = GameStateTitle then begin
    s := 'Press Spacebar to start';
    w := MeasureDefault(s);

    colour := 16 + round(8 + sin(frac(now / 4.0) * TwoPi) * 7);

    PrintBMFontTint(
      fontP92SansBold,
      s,
      (VGAWidth - w) shr 1,
      100,
      colour);
  end;

  if actualGameState = GameStatePlaying then begin
    if countdownNumber > 0 then begin
      s := I32Str(countdownNumber);
      w := MeasureDefault(s);

      PrintDefault(s, (VGAWidth - w) shr 1, 100);
    end;

    for a:=0 to high(floatingTexts) do begin
      if not floatingTexts[a].active then continue;

      with floatingTexts[a] do
        PrintDefault(text, trunc(pos.x), trunc(pos.y));
    end;

    for a:=0 to MaxLives - 1 do
      spr(texHeartEmpty, 160 + a * 20, 8);

    if lives > 0 then
      for a:=0 to lives - 1 do
        spr(texHeartFill, 160 + a * 20, 8);

    PrintDefault(i32str(score), 8, 8);
  end;
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
