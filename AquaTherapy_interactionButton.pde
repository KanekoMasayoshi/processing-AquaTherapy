// 光インタラクション切替

int FISH_COUNT  = 36;  // 魚の数
int JELLY_COUNT = 6;  // クラゲの数

int W = 960;
int H = 540;

// 光インタラクションON/OFF
final boolean LIGHT_INTERACTIVE = true;  // 魚/クラゲを光に反応させるなら true

// 表示トグル
final boolean SHOW_MOUSE_GLOW = true;  // マウスのぼや光は表示する

float LIGHT_RADIUS = 140;  // 光の見た目の半径
float LIGHT_FORCE  = 0.22;  // 魚が光を避ける力の最大値
float LIGHT_RANGE  = 170;  // 魚が光を認識して回避を始める距離

// 背景単色
final int BACKGROUND_COLOR = color(6, 18, 36);

ArrayList<Fish> fishes = new ArrayList<Fish>();
ArrayList<Jelly> jellies = new ArrayList<Jelly>();
ArrayList<Bubble> bubbles = new ArrayList<Bubble>();

PGraphics bg;

void settings() {
  size(W, H);
  smooth(8);
}

void setup() {
  frameRate(60);

  // 背景：単色
  bg = createGraphics(W, H);
  bg.beginDraw();
  bg.background(BACKGROUND_COLOR);
  bg.endDraw();

  for (int i = 0; i < FISH_COUNT; i++) fishes.add(new Fish(new PVector(random(W), random(H))));
  for (int i = 0; i < JELLY_COUNT; i++) jellies.add(new Jelly(new PVector(random(W), random(H))));
  for (int i = 0; i < 70; i++) bubbles.add(new Bubble());
}

void draw() {
  image(bg, 0, 0);

  for (Bubble b : bubbles) { b.update(); b.draw(); }  // 泡の更新

  // 見た目の光（下地）
  if (SHOW_MOUSE_GLOW) drawMouseGlow(0.06, 9);

  PVector m = new PVector(mouseX, mouseY);

  // 魚：光回避はON時のみ
  for (Fish f : fishes) {
    if (LIGHT_INTERACTIVE) f.avoidLight(m, LIGHT_RANGE, LIGHT_FORCE);
    f.update();
    f.draw();
  }

  // クラゲ：ぽよっ反発もON時のみ
  for (Jelly j : jellies) {
    if (LIGHT_INTERACTIVE) j.interactMouse(m);
    j.update();
    j.draw();
  }

  // 見た目の光（前面）
  if (SHOW_MOUSE_GLOW) drawMouseGlow(0.14, 16);

  drawFloatingDust(); 
}



// ====================
// ===== ビジュアル =====
// ====================

// 塵・泡
void drawFloatingDust() {
  noStroke();
  for (int i = 0; i < 120; i++) {
    float x = (i*71 + frameCount*0.21) % W;
    float y = (i*37 + frameCount*0.11) % H;
    float a = 16 + 12*sin((i*0.5) + frameCount*0.02);
    fill(220, 250, 255, a);
    ellipse(x, y, 1.6, 1.6);
  }
}

// マウスの光
void drawMouseGlow(float alphaBase, int rings) {
  noStroke();
  for (int i = rings; i >= 1; i--) {
    float r = LIGHT_RADIUS * (float)i / rings;
    float a = 255 * alphaBase * (1 - (i-1)/(float)rings);
    fill(200, 230, 255, a);
    ellipse(mouseX, mouseY, r*2, r*2);
  }
  fill(230, 255, 255, 40);
  ellipse(mouseX, mouseY, 16, 16);
}



// ====================
// ===== エンティティ =====
// ====================

color classicFishBlue() {
  return color(150 + random(90), 180 + random(40), 220 + random(30), 220);  // 魚の色（青〜水色）
}

class Fish {
  PVector pos, vel, acc;
  float maxSpeed = 2.2;
  float body = 10 + random(6);
  float wobbleT = random(1000);
  int c = classicFishBlue();

  Fish(PVector p) {
    pos = p.copy();
    float ang = random(TWO_PI);
    vel = PVector.fromAngle(ang).mult(random(0.5, 1.5));
    acc = new PVector();
  }

  void avoidLight(PVector m, float range, float strength) {
    float d = PVector.dist(pos, m);
    if (d < range) {
      PVector away = PVector.sub(pos, m);
      float mag = map(d, 0, range, strength, 0);
      away.setMag(mag);
      acc.add(away);
    }
  }

  void update() {
    // 横主体 + ときどき上下
    float ang = noise(wobbleT) * TWO_PI;
    PVector wander = new PVector(cos(ang), 0);
    if (random(1) < 0.10) wander.y = sin(ang);
    else wander.y = sin(ang) * 0.15;
    wander.mult(0.06);
    acc.add(wander);
    wobbleT += 0.01;

    vel.mult(0.995);
    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);

    if (pos.x < -20) pos.x = W+20;
    if (pos.x > W+20) pos.x = -20;
    if (pos.y < -20) pos.y = H+20;
    if (pos.y > H+20) pos.y = -20;
  }

  void draw() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(vel.heading());
    noStroke();

    // 体
    fill(c);
    ellipse(0, 0, body, body*0.55);

    // 尾（本体と同色）
    fill(c);
    triangle(-body*0.55, 0, -body*0.95, -body*0.2, -body*0.95, body*0.2);

    // 目
    fill(0, 100);
    ellipse(body*0.2, -body*0.07, 2.2, 2.2);
    popMatrix();
  }
}

class Jelly {
  PVector pos, vel, acc;
  float r = random(18, 30);
  float maxSpeed = 1.0; // ゆっくり
  float bobT = random(1000);
  float squish = 1.0;
  float squishVel = 0.0;
  float k = 0.20;
  float dmp = 0.80;

  Jelly(PVector p) {
    pos = p.copy();
    vel = new PVector(random(-0.4, 0.4), random(-0.15, 0.15));
    acc = new PVector();
  }

  void applyForce(PVector f) { acc.add(f); }

  void interactMouse(PVector m) {
    float d = PVector.dist(pos, m);
    if (d < r + 14) {
      PVector push = PVector.sub(pos, m);
      push.setMag(map(d, 0, r+14, 1.6, 0.2));
      applyForce(push);
      squishVel -= 0.18; // ぽよっ
    }
  }

  void update() {
    // ゆらゆら（控えめ）
    float up = sin(bobT)*0.06 - 0.006;
    applyForce(new PVector(0, up));
    bobT += 0.02;

    vel.add(acc);
    vel.limit(maxSpeed);
    pos.add(vel);
    acc.mult(0);
    vel.mult(0.995);

    if (pos.x < -r) pos.x = W + r;
    if (pos.x > W + r) pos.x = -r;
    if (pos.y < -r) pos.y = H + r;
    if (pos.y > H + r) pos.y = -r;

    // ぽよっ復帰
    float spring = -k * (squish - 1.0);
    squishVel += spring;
    squishVel *= dmp;
    squish += squishVel;
    squish = constrain(squish, 0.7, 1.3);
  }

  void draw() {
    pushMatrix();
    translate(pos.x, pos.y);
    scale(1.0 + (1.0 - squish)*0.25, squish);

    noStroke();
    for (int i = 6; i >= 1; i--) {
      float rr = r * (0.4 + i*0.12);
      fill(180, 220, 255, 18 + i*15);
      ellipse(0, 0, rr*2, rr*1.4);
    }
    stroke(190, 230, 255, 110);
    strokeWeight(1.2);
    for (int i = 0; i < 6; i++) {
      float a = i*TWO_PI/6.0 + frameCount*0.01;
      float len = r*1.6 + 6*sin(frameCount*0.03 + i);
      noFill();
      beginShape();
      for (int j = 0; j <= 12; j++) {
        float t = j/12.0;
        float x = cos(a) * (r*0.3) * (1.0 - t) + sin(a*2 + t*4 + frameCount*0.02)*3*t;
        float y = r*0.2 + len*t + sin(a + t*3 + frameCount*0.03)*2;
        vertex(x, y);
      }
      endShape();
    }
    popMatrix();
  }
}

class Bubble {
  float x, y, r, spd, swayT;
  Bubble() { reset(); y = random(H); }
  void reset() {
    x = random(W);
    y = H + random(0, 60);
    r = random(1.2, 3.2);
    spd = random(0.2, 0.7);
    swayT = random(1000);
  }
  void update() {
    y -= spd;
    x += sin(swayT)*0.3;
    swayT += 0.03;
    if (y < -10) reset();
  }
  void draw() {
    noFill();
    int mix = lerpColor(BACKGROUND_COLOR, color(255), 0.25);
    stroke(red(mix), green(mix), blue(mix), 85);
    ellipse(x, y, r*2, r*2);
  }
}
