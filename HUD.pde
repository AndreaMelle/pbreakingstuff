class HUD {

  ControlP5 cp5;
  PMatrix3D currCameraMatrix;
  PGraphics3D g3;

  Range rangeDepth;
  Range rangeHPad;

    HUD(PApplet pa) {
    g3 = (PGraphics3D)g;

    cp5 = new ControlP5(pa);

    rangeDepth = cp5.addRange("depth").setBroadcast(false) 
      .setPosition(10, 10).setSize(200, 20).setHandleSize(10)
        .setRange(0, 5000).setRangeValues(0, 5000)
          .setBroadcast(true)
            .setColorForeground(color(255, 40)).setColorBackground(color(255, 40));

    rangeHPad = cp5.addRange("hpad").setBroadcast(false) 
      .setPosition(10, 40).setSize(200, 20).setHandleSize(10)
        .setRange(0, 639).setRangeValues(0, 639)
          .setBroadcast(true)
            .setColorForeground(color(255, 40)).setColorBackground(color(255, 40));
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
    stroke(255, 0, 0);
    noFill();
    
    int padL = (int)rangeHPad.getArrayValue(0);
    int padR = (int)rangeHPad.getArrayValue(1);
    
    line(padL, 0, padL, preview.height);
    line(padR, 0, padR, preview.height);
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
  
  void addHPadRangeListener(ControlListener l) {
    rangeHPad.addListener(l);
  }

  void setDepthDefault(float depthMin, float depthMax) {
    float[] values = new float[2];
    values[0] = depthMin;
    values[1] = depthMax;
    rangeDepth.setArrayValue(values);
  }
  
  void setHPadDefault(float padL, float padR) {
    float[] values = new float[2];
    values[0] = padL;
    values[1] = padR;
    rangeHPad.setArrayValue(values);
  }
}

