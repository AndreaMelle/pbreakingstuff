class HUD {

  ControlP5 cp5;
  PMatrix3D currCameraMatrix;
  PGraphics3D g3;

  Range rangeDepth;
  Range rangeHPad;
  Range rangeVPad;
  Slider sliderX;
  Slider sliderY;
  Slider sliderZ;

  Accordion accordion;

  HUD(PApplet pa) {
    g3 = (PGraphics3D)g;

    cp5 = new ControlP5(pa);

    Group depthGroup = cp5.addGroup("depth map").setBackgroundColor(color(255, 200)).setBackgroundHeight(0);
    Group posGroup = cp5.addGroup("user pos").setBackgroundColor(color(255, 200)).setBackgroundHeight(0);

    rangeDepth = cp5.addRange("depth").setBroadcast(false) 
      .setPosition(10, 10).setSize(200, 20).setHandleSize(10)
        .setRange(0, 5000).setRangeValues(0, 5000)
          .setBroadcast(true).moveTo(depthGroup);

    rangeHPad = cp5.addRange("hpad").setBroadcast(false) 
      .setPosition(10, 40).setSize(200, 20).setHandleSize(10)
        .setRange(0, 639).setRangeValues(0, 639)
          .setBroadcast(true).moveTo(depthGroup);

    rangeVPad = cp5.addRange("vpad").setBroadcast(false) 
      .setPosition(10, 70).setSize(200, 20).setHandleSize(10)
        .setRange(0, 479).setRangeValues(0, 479)
          .setBroadcast(true).moveTo(depthGroup);

    sliderX = cp5.addSlider("x").setBroadcast(false).setPosition(10, 10).setSize(200, 20)
      .setRange(-worldW/2, worldW/2).setValue(0).setBroadcast(true).moveTo(posGroup);

    sliderY = cp5.addSlider("y").setBroadcast(false).setPosition(10, 40).setSize(200, 20)
      .setRange(0, worldH).setValue(0).setBroadcast(true).moveTo(posGroup);

    sliderZ = cp5.addSlider("z").setBroadcast(false).setPosition(10, 70).setSize(200, 20)
      .setRange(-5000, 0).setValue(0).setBroadcast(true).moveTo(posGroup);

    accordion = cp5.addAccordion("acc").setPosition(10, 10).setWidth(220)
      .addItem(depthGroup).addItem(posGroup);

    accordion.close(0);
    accordion.close(1);
    accordion.setCollapseMode(Accordion.MULTI);
  }

  void display() {
    currCameraMatrix = new PMatrix3D(g3.camera);
    hint(DISABLE_DEPTH_TEST);
    perspective();
    camera();
    resetShader();
    noLights();

    //  Start HUD
    cp5.draw();

    pushMatrix();
    PImage preview = delaBlob.getMaskPreview();
    translate(width - preview.width * 0.25, height - preview.height * 0.25);
    scale(0.25);
    noStroke();
    image(preview, 0, 0, preview.width, preview.height);
    delaBlob.displayContour();
    stroke(0, 255, 0);
    noFill();

    int padL = (int)rangeHPad.getArrayValue(0);
    int padR = (int)rangeHPad.getArrayValue(1);

    int padT = (int)rangeVPad.getArrayValue(0);
    int padB = (int)rangeVPad.getArrayValue(1);

    line(padL, 0, padL, preview.height);
    line(padR, 0, padR, preview.height);

    line(0, padT, preview.width, padT);
    line(0, padB, preview.width, padB);

    rect(0, 0, preview.width, preview.height);
    noStroke();
    popMatrix();

    //  End HUD
    hint(ENABLE_DEPTH_TEST);
    g3.camera = currCameraMatrix;
  }

  void addDepthRangeListener(ControlListener l) {
    rangeDepth.addListener(l);
  }

  void addPadRangeListener(ControlListener l) {
    rangeHPad.addListener(l);
    rangeVPad.addListener(l);
  }

  void setDepthDefault(float depthMin, float depthMax) {
    float[] values = new float[2];
    values[0] = depthMin;
    values[1] = depthMax;
    rangeDepth.setArrayValue(values);
  }

  void setPadDefault(float padL, float padR, float padT, float padB) {
    float[] values = new float[2];
    values[0] = padL;
    values[1] = padR;
    rangeHPad.setArrayValue(values);
    values[0] = padT;
    values[1] = padB;
    rangeVPad.setArrayValue(values);
  }

  void addSlidersListener(ControlListener l) {
    sliderX.addListener(l);
    sliderY.addListener(l);
    sliderZ.addListener(l);
  }

  void setSlidersDefault(float x, float y, float z) {
    sliderX.setValue(x);
    sliderY.setValue(y);
    sliderZ.setValue(z);
  }

  void save() {
    cp5.saveProperties(("hud.properties"));
  } 

  void load() {
    cp5.loadProperties(("hud.properties"));
  }
}

/*
 * Mouse Picker class
 */

class MousePicker {

  PVector camLookAt, camPos, camUp;
  float fovy, aspect, zNear, zFar;
  PVector view;
  PVector h, v;
  PVector mouse;
  PVector mouseRay, mouseRayOrigin;
  boolean enabled;

  MousePicker() {
    enabled = true;
    mouseRay = new PVector(0, 0, 0);
    mouseRayOrigin = new PVector(0, 0, 0);
  }

  void init(PVector camLookAt, PVector camPos, PVector camUp, float fovy, float aspect, float zNear) {

    this.camLookAt = camLookAt;
    this.camPos = camPos;
    this.camUp = camUp;
    this.fovy = fovy;
    this.aspect = aspect;
    this.zNear = zNear;

    this.view = PVector.sub(this.camLookAt, this.camPos);
    this.view.normalize();

    this.h = this.view.cross(this.camUp);
    this.h.normalize();

    this.v = this.h.cross(this.view);
    this.v.normalize();

    float vLength = tan(this.fovy/2.0f) * this.zNear;
    float hLength = vLength * this.aspect;

    this.v.mult(vLength);
    this.h.mult(hLength);
  }

  void update() {

    if (!enabled) {
      return;
    }

    this.mouse = new PVector(mouseX, mouseY);

    this.mouse.sub(new PVector(width/2.0f, height/2.0f));
    this.mouse.x = mouse.x / (width/2.0f);
    this.mouse.y = mouse.y / (height/2.0f);

    this.mouseRayOrigin = PVector.add(this.camPos, PVector.mult(this.view, this.zNear));
    this.mouseRayOrigin.add(PVector.mult(this.h, this.mouse.x));
    this.mouseRayOrigin.add(PVector.mult(this.v, this.mouse.y));

    this.mouseRay = PVector.sub(this.mouseRayOrigin, this.camPos);
  }

  void display () {

    if (!enabled) {
      return;
    }

    stroke(255, 0, 0);
    strokeWeight(1);

    PVector start = mouseRayOrigin;
    PVector end = PVector.add(start, PVector.mult(mouseRay, 100.0));
    line(start.x-0.01, start.y-0.01, start.z, end.x, end.y, end.z);

    noStroke();
  }

  PVector getOrigin() {
    return mouseRayOrigin;
  }

  PVector getRay() {
    return mouseRay;
  }

  void disable() {
    this.enabled = false;
  }

  void enable() {
    this.enabled = true;
  }
}

/*
 * Axis viz
 */

class Axis {

  int l;

  Axis(int length) {
    this.l = length;
  }

  void display() {
    noFill();
    strokeWeight(10);
    stroke(255, 255, 0);
    point(0, 0, 0);
    stroke(255, 0, 0);
    point(l, 0, 0);
    stroke(0, 255, 0);
    point(0, 0, -l);
    stroke(0, 0, 255);
    point(0, l, 0);


    strokeWeight(2);
    stroke(255, 0, 0);
    line(0, 0, 0, l, 0, 0);
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 0, -l);
    stroke(0, 0, 255);
    line(0, 0, 0, 0, l, 0);

    noFill();
    Mesh3D bboxMesh = worldBox.toMesh();

    beginShape(TRIANGLES);
    for (Face f : bboxMesh.getFaces()) {
      Vertex[] vertices = new Vertex[3];
      f.getVertices(vertices);
      for (int i = 0; i < vertices.length; i++) {
        Vertex v = vertices[i];
        vertex(v.x, v.y, v.z);
      }
    }
    endShape();
  }
}

