import quickhull3d.*;
import toxi.color.*;
import toxi.geom.*;
import toxi.util.datatypes.*;
import toxi.physics.*;
import toxi.physics.behaviors.*;
import gab.opencv.*;
import org.processing.wiki.triangulate.*;
import controlP5.*;
import SimpleOpenNI.*;

int GRAYSCALE = ALPHA;

float minSpeed = 0.1;
float maxSpeed = 1.0;

int numRocks = 10;
ArrayList <DelaSphere> rocks;
PShader gShader;
VerletPhysics physics;
ColorList palette;
int numCols;

PVector camLookAt;
PVector camPos;
PVector camUp;
float fovy, aspect, zNear, zFar;

HUD hud;

MousePicker mousePicker;

SimpleOpenNI  context;
boolean live;
String recordPath;

float rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, the data from openni comes upside down
float rotY = radians(0);
float zoomF = 0.25f;

DelaBlob delaBlob;

void setup() {
  size(800, 600, P3D);
  //smooth();

  live = false;
  recordPath = "rec_01.oni";

  hud = new HUD(this);

  camLookAt = new PVector(width/2.0, height/2.0, 0);
  camPos = new PVector(width/2.0, height/2.0, (height/2.0) / tan(PI*30.0 / 180.0));
  camUp = new PVector(0, 1, 0);

  fovy = PI/3.0;
  aspect = (float) width / height;
  zNear = 0.1;
  zFar = 1000000;

  mousePicker = new MousePicker();
  mousePicker.init(camLookAt, camPos, camUp, fovy, aspect, zNear);

  physics = new VerletPhysics();
  physics.setDrag(0.05f);
  physics.setWorldBounds(new AABB(new Vec3D(width/2, height/2, 0), new Vec3D(width/2, height/2, 200)));

  generateColors(160);

  gShader = loadShader("frag.glsl", "vert.glsl");

  gShader.set("specMat", 1.0, 1.0, 1.0, 1.0);
  gShader.set("specPow", 0.0);

  rocks = new ArrayList <DelaSphere>();
  delaBlob = new DelaBlob(this);

  for (int i = 0; i < numRocks; i++) {
    float radius = random(10.0f, 50.0f);
    PVector center = new PVector(random(radius, width - radius), random(radius, height - radius), random(-100, +100));
    rocks.add(new DelaSphere(center, radius, 50));
    //rocks.add(new DelaSphere(new PVector(width/2,height/2,0), 25, 50));
  }

  initKinect();
  delaBlob.init();
}

void draw() {
  update();

  pushMatrix();
  perspective(fovy, aspect, zNear, zFar);
  camera(camPos.x, camPos.y, camPos.z, camLookAt.x, camLookAt.y, camLookAt.z, camUp.x, camUp.y, camUp.z);

  background(0);

  pointLight(180, 180, 180, 2*(width/2), 2*(height/2), 500);

  for (DelaSphere s : rocks) {
    s.display();
  }

  pushMatrix();
  
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  translate(0, 0, -1000);
  
  noLights();
  resetShader();

  delaBlob.displayMesh();
  delaBlob.displayProxy();

  stroke(255, 0, 0);
  strokeWeight(1);

  PVector start = mousePicker.getOrigin();
  PVector end = PVector.add(start, PVector.mult(mousePicker.getRay(), 100.0));
  line(start.x-0.01, start.y-0.01, start.z, end.x, end.y, end.z);

  noStroke();

  popMatrix();

  popMatrix();

  hud.display();
}

void update() {
  mousePicker.update();
  physics.update();

  for (DelaSphere s : rocks) {
    s.update();
    if (s.dead) {
      float radius = random(10.0f, 50.0f);
      //PVector center = new PVector(random(radius, width - radius), random(radius, height - radius), random(-100, +100));
      PVector center = new PVector(width/2, height/2, 0);
      s.reset(center, radius);
    }
  }

  context.update();
  if ((context.nodes() & SimpleOpenNI.NODE_DEPTH) == 0 || (context.nodes() & SimpleOpenNI.NODE_IMAGE) == 0)
  {
    println("No frame.");
    return;
  }
  delaBlob.update();

  ArrayList <PVector> pproxy = delaBlob.getPolyProxy();

  for (PVector p : pproxy) {
    for (DelaSphere s : rocks) {
      s.checkCollision(p);
    }
  }
}

void keyPressed() {
  //if (key == ' ') { 
  //rocks.get((int)random(0, rocks.size())).explode();
  //}
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

