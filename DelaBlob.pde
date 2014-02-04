/*
 * This class manages kinect data, to create a delaunay triangulation of the 3d data
 * and it's contour based proxy
 */

class DelaBlob implements ControlListener {

  PApplet that;

  // params
  int depthMin, depthMax;
  int padL, padR, padT, padB;
  int pointSkip;
  int polyApprox;

  // image processing
  int depthW, depthH, rgbW, rgbH;
  int[] depthMap, depthMask;
  PVector[] realWorldMap;
  PImage rgbImg, depthImg, depthMaskSrc;
  OpenCV opencv;
  ArrayList <Contour> contours;
  ArrayList <PVector> polygon;
  Contour maxContour;
  float maxArea = 0;
  int filterSize;
  boolean hasBlob;

  // geometry
  float zoomF;
  PVector pos;
  ArrayList triangles, trianglesRaw, points;

  // rendering
  ArrayList <Color> colors;

  // physics proxy
  ArrayList <PVector> polyProxy;
  AABB bbox;

  DelaBlob(PApplet pa, PVector pos, int pointSkip, int polyApprox) {
    this.pointSkip = pointSkip;
    this.polyApprox = polyApprox;
    this.that = pa;
    this.pos = pos;
    depthMin = 100;
    depthMax = 1800;
    padL = 50;
    padR = 600;
    padT = 0;
    padB = 479;
    zoomF = 0.25f;
    filterSize = 5;
    hasBlob = false;
    triangles = new ArrayList();
    trianglesRaw = new ArrayList();
    points = new ArrayList();
    colors = new ArrayList <Color> ();
    polyProxy = new ArrayList <PVector> ();
    bbox = new AABB();
  }

  void init() {
    depthW = context.depthWidth();
    depthH = context.depthHeight();
    rgbW = context.rgbWidth();
    rgbH =  context.rgbHeight();
    depthMask = new int[depthW * depthH];
    opencv = new OpenCV(that, depthW, depthH);
    depthMaskSrc = createImage(depthW, depthH, GRAYSCALE);
    initHud();
  }

  void update() {

    points.clear();
    triangles.clear();
    colors.clear();
    polyProxy.clear();
    hasBlob = false;

    depthMap = context.depthMap();
    depthImg = context.depthImage();
    rgbImg = context.rgbImage();
    realWorldMap = context.depthMapRealWorld();

    for (int x=0;x<depthW;x+=1) {
      for (int y=0;y<depthH;y+=1) {

        int idx = x + y * depthW;
        depthMask[idx] = 0;

        if ( !(x > padL && x < padR && y > padT && y < padB) ) {
          continue;
        }

        float d = depthMap[idx];

        if (d > depthMin && d < depthMax) {
          depthMask[idx] = 255;

          if ( (x % (2 * pointSkip)) == 0 && (y % (2 * pointSkip)) == 0) {
            PVector p = realWorldMap[idx];

            if (abs(p.z) > depthMin && abs(p.z ) < depthMax) {
              points.add(p);
            }
          }
        }
      }
    }

    if (points.size() <= 0) {
      return;
    }

    depthMaskSrc.pixels = depthMask;
    depthMaskSrc.updatePixels();
    opencv.loadImage(depthMaskSrc);
    contours = opencv.findContours();

    if (contours.size() <= 0) {
      return;
    }

    hasBlob = true;

    maxArea = 0;

    for (Contour contour : contours) {
      float area = contour.area();
      if (area > maxArea) {
        maxArea = area;
        maxContour = contour;
      }
    }

    maxContour.setPolygonApproximationFactor(polyApprox);
    polygon = maxContour.getPolygonApproximation().getPoints();

    // Compute polygonal proxy and bbox
    PVector minSpan = new PVector(10000, 10000, 10000);
    PVector maxSpan = new PVector(0, 0, 0);

    for (PVector p : polygon) {

      PVector pAvg = new PVector(0, 0, 0);
      int n = 0;

      int xMin = (int)p.x - floor(filterSize / 2);
      int xMax = (int)p.x + floor(filterSize / 2);
      int yMin = (int)p.y - floor(filterSize / 2);
      int yMax = (int)p.y + floor(filterSize / 2);

      for (int i = xMin; i <= xMax; i++) {
        for (int j = yMin; j <= yMax; j++) {

          int idx = min(max(0, i), depthW - 1) + min(max(0, j), depthH - 1) * depthW;

          if (depthMask[idx] > 0) {
            pAvg.add(realWorldMap[idx]);
            n++;
          }
        }
      }

      pAvg.div(n);

      pAvg.add(0, 0, pos.z);
      pAvg.mult(zoomF);
      //pAvg.y = -pAvg.y;
      //pAvg.z = -pAvg.z;
      pAvg.add(pos.x, pos.y, 0);

      updateBBox(pAvg, minSpan, maxSpan);

      polyProxy.add(pAvg);
    }

    // finalize bbox
    //PVector center = PVector.add(minSpan, maxSpan);
    //center.div(2);
    //PVector extent = PVector.sub(maxSpan, minSpan);
    //extent.div(2);
    //bbox = new AABB(Vec3D(center.x, center.y, center.z), Vec3D(extent.x, extent.y, extent.z));
    bbox = AABB.fromMinMax(new Vec3D(minSpan.x, minSpan.y, minSpan.z), new Vec3D(maxSpan.x, maxSpan.y, maxSpan.z));

    trianglesRaw = Triangulate.triangulate(points);

    for (int i = 0; i < trianglesRaw.size(); i++) {
      Triangle t = (Triangle)trianglesRaw.get(i);    

      float[] real = new float[3];
      float[] proj = new float[3];

      real[0] = (t.p1.x + t.p2.x + t.p3.x) / 3.0;
      real[1] = (t.p1.y + t.p2.y + t.p3.y) / 3.0;
      real[2] = (t.p1.z + t.p2.z + t.p3.z) / 3.0;

      context.convertRealWorldToProjective(real, proj);

      int idx = (int)proj[0] + (int)proj[1] * depthW;
      if (depthMask[idx] > 0) {
        triangles.add(t);
        color c = rgbImg.get((int)proj[0], (int)proj[1]);
        colors.add(new Color(c));
      }
    }
  }

  void displayMesh() {
    pushMatrix();

    translate(pos.x, pos.y, 0);
    //rotateX(radians(180));
    scale(zoomF);
    translate(0, 0, pos.z);

    strokeWeight(1 / zoomF);

    beginShape(TRIANGLES);
    for (int i = 0; i < triangles.size(); i++) {
      Triangle t = (Triangle)triangles.get(i);
      //fill(colors.get(i).get());
      vertex(t.p1.x, t.p1.y, t.p1.z);
      vertex(t.p2.x, t.p2.y, t.p2.z);
      vertex(t.p3.x, t.p3.y, t.p3.z);
    }
    endShape();

    popMatrix();
    
    if(_DEBUG) {
      displayProxy();
      displayBBox();
    }
  }

  void displayProxy() {
    stroke(255, 0, 0);
    strokeWeight(5);
    for (PVector p : polyProxy) {
      point(p.x, p.y, p.z);
    }
  }

  void displayBBox() {
    stroke(0, 255, 0);
    strokeWeight(1);
    noFill();
    Mesh3D bboxMesh = bbox.toMesh();

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

  void displayContour() {
    noFill();
    strokeWeight(4);
    stroke(255, 0, 0);
    beginShape();
    for (PVector point : polygon) {
      vertex(point.x, point.y);
    }
    endShape();
  }

  // returns a small version of the valid depth mask  
  PImage getMaskPreview() {
    return depthMaskSrc;
  }

  ArrayList <PVector> getPolyProxy() {
    return polyProxy;
  }

  AABB getBBox() {
    return bbox;
  }

  void updateBBox(PVector p, PVector minSpan, PVector maxSpan) {
    if (p.x < minSpan.x) {
      minSpan.x = p.x;
    }

    if (p.x > maxSpan.x) {
      maxSpan.x = p.x;
    }

    if (p.y < minSpan.y) {
      minSpan.y = p.y;
    }

    if (p.y > maxSpan.y) {
      maxSpan.y = p.y;
    }

    if (p.z < minSpan.z) {
      minSpan.z = p.z;
    }

    if (p.z > maxSpan.z) {
      maxSpan.z = p.z;
    }
  }

  /*
   * HUD related
   */

  void initHud() {
    hud.addDepthRangeListener(this);
    hud.setDepthDefault(this.depthMin, this.depthMax);
    hud.addPadRangeListener(this);
    hud.setPadDefault(this.padL, this.padR, this.padT, this.padB);
    hud.addSlidersListener(this);
    hud.setSlidersDefault(pos.x, pos.y, pos.z, zoomF);
  }

  public void controlEvent(ControlEvent event) {
    if (event.isFrom("depth")) {
      depthMin = int(event.getController().getArrayValue(0));
      depthMax = int(event.getController().getArrayValue(1));
    } 
    else if (event.isFrom("hpad")) {
      padL = int(event.getController().getArrayValue(0));
      padR = int(event.getController().getArrayValue(1));
    } 
    else if (event.isFrom("vpad")) {
      padT = int(event.getController().getArrayValue(0));
      padB = int(event.getController().getArrayValue(1));
    }
    else if (event.isFrom("x")) {
      pos.x = int(event.getController().getValue());
    }
    else if (event.isFrom("y")) {
      pos.y = int(event.getController().getValue());
    }
    else if (event.isFrom("z")) {
      pos.z = int(event.getController().getValue());
    }
    else if (event.isFrom("zoom")) {
      zoomF = event.getController().getValue();
    }
  }
}

