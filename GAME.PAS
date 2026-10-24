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
  P92BMFON, P92GRAPH, P92TEX, P92TEXFX,
  P92PANIC, P92TIME, P92VGA,
  ASSETS;

const
  TwoPi = 2 * Pi;

  { in seconds }
  InvincibleDuration = 3.0;
  { 1 / spawn rate }
  FoodSpawnRate = 1.25;
  FoodDropSpeed = 120;
  ConveyorSpeed = 80;

  CharHeadX = 32;
  CharHeadY = 76;
  PipeX = DefaultVGAWidth - 48;
  PipeY = 0;

  JudgementX = 64;
  ConveyorItemY = 100;
  MaxLives = 4;
  HeartBarX = 20;
  HeartBarY = 50;

{$ifdef release}
  MaxFullness = 1.0;
{$else}
  MaxFullness = 0.1;
{$endif}

type
  TGameState = (
    GameStateTitle,
    GameStatePlaying,
    GameStateWin,
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
    pos: TPoint;
    texture: PTexture;
    isHarming: boolean;
    isFalling: boolean;
  end;

  TFloatingText = record
    active: boolean;
    text: string;
    endTick: double;
    pos: TPoint;
    vel: TVector;
  end;

const
  SafeFoodList: array[0..1] of TFoodType = (
    FoodCookie,
    FoodLemon
  );

var
  { Game state variables }
  actualGameState: TGameState;

  countdownNumber: integer;
  { uses real time }
  countdownNextTick: double;

  { Only applies in the playing state }
  gameTime: double;
  { score: longint; }
  fullness: double;

  isMouthOpen: boolean;
  lives: integer;
  { uses gameTime }
  invincibleEndTick: double;
  isBlinkingVisible: boolean;

  foodList: array[0..19] of TFood;
  { uses gameTime }
  nextSpawnTick: double;

  floatingTexts: array[0..9] of TFloatingText;
  transitionTime: double;

procedure ReplaceColour(var tex: TTexture; const oldColour, newColour: byte);
var
  a: word;
begin
  if not assigned(tex.data) then exit;

  for a:=0 to tex.width * tex.height - 1 do
    if tex.data^[a] = oldColour then
      tex.data^[a] := newColour;
end;

procedure InitTitleState;
begin
  actualGameState := GameStateTitle;
end;

procedure ResetGameplayState;
begin
  RandSeed := trunc(GetTimer);

  gameTime := 0.0;
  { score := 0; }
  fullness := 0.0;
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

procedure InitWinTransition;
begin
  actualGameState := GameStateWin;
  transitionTime := 0.0;
end;

procedure SpawnFood(const foodType: TFoodType; const x, y: double);
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
  foodList[idx].pos.x := x;
  foodList[idx].pos.y := y;

  foodList[idx].isFalling := true;

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

procedure UnsafeSpr(const tex: TTexture; const x, y: integer);
const
  TransparencyKey = 13;
var
  srcX, srcY: integer;
  rowOffset, pxOffset: longint;

  startY, endY: integer;
  startX, endX: integer;

  pixelData: pointer;
  srcOffset, destOffset: word;
  drawCount: word;
begin
  pixelData := tex.data;

  startX := 0;
  endX := tex.width - 1;

  srcOffset := startX;
  destOffset := word(y) * VGAWidth + word(x + startX);
  drawCount := endX - startX + 1;

  { Render logic }

  for srcY := 0 to tex.height-1 do begin
    asm
      push ds

      les di, backBuffer
      add di, destOffset

      { Load DS:SI with the source tex's data }
      lds si, pixelData
      add si, srcOffset
      mov cx, drawCount
      mov ah, TransparencyKey

    @loop:
      lodsb
      cmp al, ah
      je @skip
      mov es:[di], al

    @skip:
      inc di
      dec cx
      jnz @loop

      pop ds
    end;

    inc(srcOffset, tex.width);
    inc(destOffset, VGAWidth)
  end;
end;


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

  LoadTex(texPipe, 'IMG\PIPE.BMP');

  LoadBMFont(fontP92SansBold, 'FONTS\P92SAN8B.TXT');
  { LoadBMFont(fontP92SansBoldBlack, 'FONTS\P92SAN8B.TXT'); }
  LoadBMFont(fontX14y20pxScoreDozer, 'FONTS\SCOREDOZ.TXT');
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

  CloneBMFont(fontP92SansBold, fontP92SansBoldBlack);
  ReplaceColour(fontP92SansBoldBlack.texture, 15, 0);

  InitTitleState;
  ResetGameplayState;
end;

{ Handle game state updates here }
procedure Update; far;
var
  now: double;
  a, pick: integer;
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

      if foodList[a].isFalling then begin
        foodList[a].pos.y := foodList[a].pos.y + FoodDropSpeed * DeltaTime;

        if foodList[a].pos.y >= ConveyorItemY then begin
          foodList[a].pos.y := ConveyorItemY;
          foodList[a].isFalling := false;
        end;
      end;

      if not foodList[a].isFalling then begin
        foodList[a].pos.x := foodList[a].pos.x - ConveyorSpeed * DeltaTime;

        if foodList[a].pos.x < JudgementX then begin
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
            { inc(score, 100); }
            fullness := fullness + 0.05;
            SpawnFloatingText('+1', JudgementX, 100);

            if fullness >= MaxFullness then
              InitWinTransition;
          end;

          foodList[a].active := false;

          continue
        end;
      end;
    end;

    if gameTime >= nextSpawnTick then begin
      nextSpawnTick := gameTime + 1 / FoodSpawnRate;

      pick := random(4);

      case pick of
        1: SpawnFood(FoodBomb, PipeX + 20, PipeY);
        else
          SpawnFood(
            SafeFoodList[
              random(high(SafeFoodList) + 1)],
              PipeX + 20, PipeY);
      end;
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

  if actualGameState = GameStateWin then begin
    transitionTime := transitionTime + DeltaTime;
  end;
end;

{ Render logic }
procedure Draw; far;
var
  a: integer;
  w: integer;
  s: string;
  colour: byte;
  shiftX, renderX: integer;
  wipeY: integer;
  now: double;
begin
  now := GetTimer;

  Cls($67);

  shiftX := trunc(frac(now) * 10);

  for a:=-(VGAHeight div 10) to VGAWidth div 10 do
    line(
      a * 10 + shiftX, 0,
      a * 10 + shiftX + VGAHeight, VGAHeight,
      $0F);

  for a:=0 to high(foodList) do begin
    if not foodList[a].active then continue;

    { Debug judgement line }
    { VLine(trunc(foodList[a].x), 68, 132, $0F); }

    renderX := trunc(foodList[a].pos.x - foodList[a].texture^.width / 2);
    Spr(foodList[a].texture^, renderX, trunc(foodList[a].pos.y));
  end;

  UnsafeSpr(texPipe, PipeX, PipeY);

  if not IsInvincible or (isBlinkingVisible and IsInvincible) then begin
    if isMouthOpen then
      spr(texKaylaOpen, CharHeadX, CharHeadY)
    else
      spr(texKaylaNormal, CharHeadX, CharHeadY);
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

      PrintBlack(s, (VGAWidth - w) shr 1, 100);
    end;

    for a:=0 to high(floatingTexts) do begin
      if not floatingTexts[a].active then continue;

      with floatingTexts[a] do
        PrintDefault(text, trunc(pos.x), trunc(pos.y));
    end;

    for a:=0 to MaxLives - 1 do
      spr(texHeartEmpty, HeartBarX + a * 20, HeartBarY);

    if lives > 0 then
      for a:=0 to lives - 1 do
        spr(texHeartFill, HeartBarX + a * 20, HeartBarY);

    { PrintScoreDozer(i32str(score), 8, 8); }
    s := i32str(round(fullness * 100)) + '%';
    w := MeasureScoreDozer(s);
    PrintScoreDozer(s, (VGAWidth - w) shr 1, 32);
  end;


  if actualGameState = GameStateWin then begin
    wipeY := trunc(transitionTime / 3.0 * VGAHeight);

    { TODO: Implement the wipe sprite}
  end;

  { print('MemAvail: ' + i32str(longint(MemAvail)), 0, 20, 0); }
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
