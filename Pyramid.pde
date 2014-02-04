class SpikyFloor {

  PVector pos, ext;
  int subX, subZ;
  float noiseStrength;
  //PShape spikyFloor;

  ArrayList <Pyramid> spikes;

  SpikyFloor(PVector pos, PVector ext, int subX, int subZ) {
    
    noiseStrength = ext.y * 80.0 / 100.0;
    float noiseScale=2;
    this.pos = pos;
    this.ext = ext;
    this.subX = subX;
    this.subZ = subZ;
    spikes = new ArrayList <Pyramid> ();

    int stepX = (int)ext.x / subX;
    int stepZ = (int)ext.z / subZ;
    
    float ni = 0;
    float nj = 0;

    for (int i = -(int)ext.x/2; i < (int)ext.x/2; i+=stepX, ni+=noiseScale) {
      for (int j = -(int)ext.z/2; j < (int)ext.z/2; j+=stepZ, nj+=noiseScale) {
        
        float n = noise( ni, nj); //random(0,1.0);
        n = map(n, 0, 1.0, -noiseStrength, noiseStrength);
        
        float nW = map(noise(ni), 0, 1.0, -noiseStrength/2, noiseStrength); 
        float nD = map(noise(nj), 0, 1.0, -noiseStrength/2, noiseStrength); 
        
        float nX = map(noise(2*ni), 0, 1.0, -stepX * 0.2, stepX * 0.2); 
        float nZ = map(noise(2*ni + noiseScale/2), 0, 1.0, -stepZ * 0.2, stepZ * 0.2); 
        
        spikes.add(new Pyramid(
        new PVector(i + stepX/2 + nX, 0, j + stepZ/2 + nZ), 
        new PVector(stepX + nW, ext.y + n, stepZ + nD)));
      }
    }
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    for (Pyramid p : spikes) {
      p.display();
    }
    popMatrix();
  }
}


class Pyramid {

  PVector pos;
  PVector ext;
  PVector[] v;
  PShape pyr;

  Pyramid(PVector pos, PVector ext) {

    this.pos = pos;
    this.ext = ext;

    v = new PVector[5];
    v[0] = new PVector(0.5, 1, 0.5);
    v[1] = new PVector(0, 0, 0);
    v[2] = new PVector(0, 0, 1);
    v[3] = new PVector(1, 0, 1);
    v[4] = new PVector(1, 0, 0);

    pyr = createShape();
    pyr.beginShape(TRIANGLE_FAN); // TRIANGLE_FAN is suited for this, it starts with the center point c[0]
    pyr.translate(-0.5, 0, -0.5);
    for (int i=0; i<5; i++) {
      pyr.vertex(v[i].x, v[i].y, v[i].z);
    }
    pyr.vertex(v[1].x, v[1].y, v[1].z);
    pyr.endShape();
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    scale(ext.x, ext.y, ext.z);
    shape(pyr);
    popMatrix();
  }
}

