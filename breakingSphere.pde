import quickhull3d.*;
import toxi.color.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.util.datatypes.*;
import toxi.physics.*;
import toxi.physics.behaviors.*;
import gab.opencv.*;
import org.processing.wiki.triangulate.*;
import controlP5.*;
import SimpleOpenNI.*;

int GRAYSCALE = ALPHA;
boolean _DEBUG = false;

SimpleOpenNI  context;
boolean live;
String recordPath;

// graphics settings
PShader gShader;
ColorList palette;
int numCols;
PVector camLookAt;
PVector camPos;
PVector camUp;
float fovy, aspect, zNear, zFar;

// graphics objetcs
HUD hud;
Axis axis;
MousePicker mousePicker;
ArrayList <DelaSphere> rocks;
DelaBlob delaBlob;
Floor floor;
Billboard back;
SpikyFloor spikes;

// physics
VerletPhysics physics;
float worldRatio;
int worldW;
int worldH;
int worldD;
AABB worldBox;
PVector lightPos;

// performance settings
int rockRes = 10; //50
int pointSkip = 10; //5
int polyApprox = 7; //3
int numRocks = 40;

void setup() {
  size(800, 800, P3D);
  //smooth();

  live = false;
  recordPath = "rec_02.oni";

  //worldRatio = 9.0f / 16.0f;
  worldW = 2000;
  worldH = 1200;
  worldD = 200;
  worldBox = new AABB(new Vec3D(0, worldH/2, 0), new Vec3D(worldW/2, worldH/2, worldD/2));
  lightPos = new PVector(0, 2*worldH, 0);

  camLookAt = new PVector(width/2, height/2, 0);
  camPos = new PVector(width/2, -height, (height/2.0) / tan(PI*30.0 / 180.0) + 1500);
  camUp = new PVector(0, 1, 0);
  fovy = PI/3.0;
  aspect = (float) width / height;
  zNear = 0.1;
  zFar = 1000000;

  gShader = loadShader("frag.glsl", "vert.glsl");
  generateColors(160);

  hud = new HUD(this);
  axis = new Axis(200);

  mousePicker = new MousePicker();
  mousePicker.init(camLookAt, camPos, camUp, fovy, aspect, zNear);
  mousePicker.disable();

  physics = new VerletPhysics();
  physics.setDrag(0.05f);
  physics.setWorldBounds(worldBox);

  rocks = new ArrayList <DelaSphere>();

  for (int i = 0; i < numRocks; i++) {
    rocks.add(new DelaSphere(rockRes));
  }

  floor = new Floor(worldW, worldD, 5, new PVector(0, 0, 0));
  back = new Billboard(new PVector(0, worldH/2, worldD/2), worldW, worldH );
  spikes = new SpikyFloor(new PVector(0, 0, 0), new PVector(worldW, 100, worldD), 30, 3);

  delaBlob = new DelaBlob(this, new PVector(0, 0, 0), pointSkip, polyApprox);

  initKinect();
  delaBlob.init();

  hud.load();
  camPos.y = hud.getCamY();
  camPos.z = hud.getCamZ();
  fovy = hud.getCamZoom();
  camLookAt.y = hud.getLookAtY();
  camLookAt.z = hud.getLookAtZ();
  aspect = hud.getW() / hud.getH();
}

void draw() {
  update();

  // camera is not affected by transformation stack
  aspect = hud.getW() / hud.getH();
  perspective(hud.getCamZoom(), aspect, zNear, zFar);
  camera(camPos.x, hud.getCamY(), hud.getCamZ(), camLookAt.x, hud.getLookAtY(), hud.getLookAtZ(), camUp.x, camUp.y, camUp.z);

  pushMatrix();
  translate(width/2, height/2, 0);
  scale(1.0, -1.0, -1.0);

  background(0);

  resetShader();
  noStroke();
  back.display();

  stroke(0, 40);
  fill(255);

  float w = 255.0/255.0;
  //shader(gShader);

  //pointLight(255, 255, 255, lightPos.x, lightPos.y, lightPos.z);
  
  float li = 255.0 / 2.0;
  float li2 = li + 100;
  
  directionalLight(li2, li2, li2, 1, -1, 1);
  ambientLight(li, li, li);
  ambient(255, 255, 255);

  gShader.set("ambientMat", 25.0/255.0, 100.0/255.0, 122.0/255.0, 1.0);
  gShader.set("diffuseMat", 25.0/255.0, 100.0/255.0, 122.0/255.0, 1.0);
  shader(gShader);
  floor.display();

  if (hud.drawSpikes()) {
    gShader.set("ambientMat", 25.0/255.0, 100.0/255.0, 122.0/255.0, 1.0);
    gShader.set("diffuseMat", 211.0/255.0, 0.0, 24.0/255.0, 1.0);
    shader(gShader);
    spikes.display();
  }
  
  for (DelaSphere s : rocks) {
    shader(gShader);
    s.display();
  }
  
  gShader.set("ambientMat", w, w, w, 1.0);
    gShader.set("diffuseMat", w, w, w, 1.0);
    shader(gShader);

  delaBlob.displayMesh();
  if (_DEBUG) {
    mousePicker.display();
    axis.display();
    noFill();
    strokeWeight(10);
    stroke(255, 255, 0);
    point(lightPos.x, lightPos.y, lightPos.z);
  }


  popMatrix();

  hud.display();
}

void update() {
  context.update();
  if ((context.nodes() & SimpleOpenNI.NODE_DEPTH) == 0 || (context.nodes() & SimpleOpenNI.NODE_IMAGE) == 0)
  {
    println("No frame.");
    return;
  }

  delaBlob.update();
  ArrayList <PVector> pproxy = delaBlob.getPolyProxy();

  mousePicker.update();
  physics.update();

  boolean spanned = false;

  for (DelaSphere s : rocks) {
    if (s.dead) {
      if (!spanned) {
        spanRock(s);
        spanned = true;
      }
    } 
    else {
      s.update();
      for (PVector p : pproxy) {
        s.checkCollision(p);
      }
      s.checkFloor();
    }
  }
}

int spanDelay = 10;
void spanRock(DelaSphere r) {

  if (spanDelay-- > 0) {
    return;
  }

  if (delaBlob.hasBlob) {
    spanDelay = 30;
    AABB bbox = delaBlob.getBBox();
    float minRockRadius = 20.0f;
    float maxRockRadius = 80.0f;
    float radius = random(minRockRadius, maxRockRadius);

    float xMax = worldW/8 - radius;
    float yMin = worldH - radius;//radius;
    float yMax = worldH - radius;
    float zMax = worldD/8 - radius;

    PVector center = new PVector(random(-xMax, xMax), random(yMin, yMax), random(-zMax, zMax));

    while (bbox.containsPoint (new Vec3D (center.x, center.y, center.z))) {
      center = new PVector(random(-xMax, xMax), random(yMin, yMax), random(-zMax, zMax));
    }
    r.set(center, radius);
  }
}

void keyPressed() {
  //if (key == ' ') { 
  //rocks.get((int)random(0, rocks.size())).explode();
  //}

  if (key=='1') {
    hud.save();
  } 
  else if (key=='2') {
    hud.load();
  }
}

void initKinect() {
  if (live) {
    context = new SimpleOpenNI(this);
    if (context.isInit() == false)
    {
      println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
      exit();
      return;
    }
  } 
  else {
    context = new SimpleOpenNI(this, recordPath);
  }

  context.enableDepth();
  context.enableRGB();
  context.setMirror(true);
  context.alternativeViewPointDepthToImage();
}

void generateColors (int numCols) {
  ColorTheme t = new ColorTheme("test");
  t.addRange("soft ivory", 0.5);
  t.addRange("intense goldenrod", 0.25);
  t.addRange("warm saddlebrown", 0.15);
  t.addRange("fresh teal", 0.05);
  t.addRange("bright yellow", 0.05);
  t.addRange(ColorRange.BRIGHT, TColor.newRandom(), random(0.02, 0.05));
  palette = t.getColors(numCols);
}

