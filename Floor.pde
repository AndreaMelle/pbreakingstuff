class Floor {

  int xDim, zDim;
  int subDiv;
  PVector pos;
  PShape floor;

  Floor(int xDim, int zDim, int subDiv, PVector pos) {

    this.xDim = xDim;
    this.zDim = zDim;
    this.subDiv = subDiv;
    this.pos = pos;

    int stepX = xDim / subDiv;
    int stepZ = zDim / subDiv;

    floor = createShape();
    floor.beginShape(TRIANGLES);

    for (int i = -xDim/2; i < xDim/2; i+=stepX) {
      for (int j = -zDim/2; j < zDim/2; j+=stepZ) {
        floor.vertex(i, 0, j);
        floor.vertex(i, 0, j + stepZ);
        floor.vertex(i + stepX, 0, j);

        floor.vertex(i + stepX, 0, j);
        floor.vertex(i, 0, j + stepZ);
        floor.vertex(i + stepX, 0, j + stepZ);
      }
    }

    floor.endShape();
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    shape(floor);
    popMatrix();
  }
}

