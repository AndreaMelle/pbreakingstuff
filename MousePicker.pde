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
    mouseRay = new PVector(0,0,0);
    mouseRayOrigin = new PVector(0,0,0);
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

