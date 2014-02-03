/*
 * This class manages kinect data, to create a delaunay triangulation of the 3d data
 * and it's contour based proxy
 */

class DelaBlob implements ControlListener {

  PApplet that;

  int depthMin;
  int depthMax;
  int padL;
  int padR;

  int depthW, depthH, rgbW, rgbH;
  int[] depthMap;
  PVector[] realWorldMap;
  PImage rgbImg;
  PImage depthImg;

  int[] depthMask;

  ArrayList triangles;
  ArrayList trianglesRaw;
  ArrayList points;
  ArrayList <Color> colors;
  int pointSkip;

  PImage depthMaskSrc;
  OpenCV opencv;
  ArrayList <Contour> contours;
  ArrayList <PVector> polygon;
  Contour maxContour;
  float maxArea = 0;
  //PGraphics buffer; // offscreen buffer for contour drawing
  //PImage contourMask;

  ArrayList <PVector> polyProxy;

  DelaBlob(PApplet pa) {
    pointSkip = 5;
    this.that = pa;
    depthMin = 100;
    depthMax = 1800;
    padL = 50;
    padR = 600;
  }

  void init() {

    hud.addDepthRangeListener(this);
    hud.setDepthDefault(this.depthMin, this.depthMax);

    hud.addHPadRangeListener(this);
    hud.setHPadDefault(this.padL, this.padR);

    depthW = context.depthWidth();
    depthH = context.depthHeight();
    rgbW = context.rgbWidth();
    rgbH =  context.rgbHeight();
    depthMask = new int[depthW * depthH];
    triangles = new ArrayList();
    trianglesRaw = new ArrayList();
    points = new ArrayList();
    colors = new ArrayList <Color> ();
    opencv = new OpenCV(that, depthW, depthH);
    depthMaskSrc = createImage(depthW, depthH, GRAYSCALE);
    //buffer = createGraphics(depthW, depthH, P2D);
    //contourMask = createImage(depthW, depthH, RGB);
    polyProxy = new ArrayList <PVector> ();
  }

  void update() {

    points.clear();
    triangles.clear();
    colors.clear();
    polyProxy.clear();

    depthMap = context.depthMap();
    depthImg = context.depthImage();
    rgbImg = context.rgbImage();
    realWorldMap = context.depthMapRealWorld();

    for (int x=0;x<depthW;x+=1) {
      for (int y=0;y<depthH;y+=1) {

        int idx = x + y * depthW;
        depthMask[idx] = 0;

        if ( !(x > padL) || !(x < padR) ) {
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

    maxArea = 0;

    for (Contour contour : contours) {
      float area = contour.area();
      if (area > maxArea) {
        maxArea = area;
        maxContour = contour;
      }
    }

    maxContour.setPolygonApproximationFactor(3);
    polygon = maxContour.getPolygonApproximation().getPoints();

    int filterSize = 5;

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
      polyProxy.add(pAvg);
    }

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
    
    
    
    stroke(0, 40);

    beginShape(TRIANGLES);
    for (int i = 0; i < triangles.size(); i++) {
      Triangle t = (Triangle)triangles.get(i);
      fill(colors.get(i).get());
      vertex(t.p1.x, t.p1.y, t.p1.z);
      vertex(t.p2.x, t.p2.y, t.p2.z);
      vertex(t.p3.x, t.p3.y, t.p3.z);
    }
    endShape();

    noStroke();
    popMatrix();
  }

  void displayProxy() {
    pushMatrix();
    stroke(255, 0, 0);
    strokeWeight(5);

    for (PVector p : polyProxy) {
      point(p.x, p.y, p.z);
    }

    popMatrix();
  }

  // returns a small version of the valid depth mask  
  PImage getMaskPreview() {
    return depthMaskSrc;
  }

  ArrayList <PVector> getPolyProxy() {
    return polyProxy;
  }

  void displayContour() {
    noFill();
    strokeWeight(4);
    //maxContour.draw();
    stroke(255, 0, 0);
    beginShape();
    for (PVector point : polygon) {
      vertex(point.x, point.y);
    }
    endShape();
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
  }

  // TODO: getters and setters
}

