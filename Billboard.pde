class Billboard {

  PVector pos;
  int w, h;

  PShape bill;

  Billboard(PVector pos, int w, int h) {
    this.pos = pos;
    this.w = w;
    this.h = h;
    
    PImage img = loadImage("background.png");


    bill = createShape();
    
    bill.beginShape(TRIANGLES);
    bill.translate(-0.5, -0.5, -0.5);
    bill.texture(img);
    bill.noStroke();
    bill.vertex(0, 0, 0, 0, 0);
    bill.vertex(0, 1, 0, 0, 1080);
    bill.vertex(1, 0, 0, 1920, 0);
    
    bill.vertex(1, 0, 0, 1920, 0);
    bill.vertex(0, 1, 0, 0, 1080);
    bill.vertex(1, 1, 0, 1920, 1080);
    

    bill.endShape();
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    scale(w, -h, 1.0);
    shape(bill);
    popMatrix();
  }
}

