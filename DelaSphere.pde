class DelaSphere {

  //ArrayList <PVector> vertices = new ArrayList <PVector> ();
  //ArrayList <PVector> normals = new ArrayList <PVector> ();
  //ArrayList <PVector> texCoords = new ArrayList <PVector> ();

  // Drawing data
  ArrayList <PVector[]> faces;
  ArrayList <PVector> internal;
  ArrayList <PVector> faceNormals;

  // Proxy
  Sphere proxy;
  VerletParticle vp;
  AttractionBehavior abh;

  // these are the centers of Delaunay triangles a.k.a. vertices of Voronoi
  // for generation only
  Point3d[] qPoints;
  Point3d[] qVertices;
  int[][] qFaceIndices;

  int numPoints;
  float radius;
  PVector pos;
  boolean broken;
  float[] speed;
  int transparency;
  int start;
  color fill;
  boolean dead;

  DelaSphere (PVector pos, float radius, int numPoints) {
    this.numPoints = numPoints;
    this.reset(pos, radius);
  }

  void reset(PVector pos, float radius) {
    this.pos = pos;
    this.radius = radius;
    proxy = new Sphere(radius);

    vp = new VerletParticle(pos.x, pos.y, pos.z);
    //abh = new AttractionBehavior(vp, radius * 2.5 + max(0, 50 - radius), -1.2f, 0.01f);
    abh = new AttractionBehavior(vp, radius * 2.5, -1.2f, 0.01f);


    faces = new ArrayList <PVector[]> ();
    internal = new ArrayList <PVector> ();
    faceNormals = new ArrayList <PVector> ();

    this.samplePoints();
    this.computeDelaunay();

    speed = new float[faces.size()];
    for (int i = 0; i < speed.length; i++) {
      speed[i] = random(minSpeed, maxSpeed);
    }

    this.transparency = 255;
    fill = palette.get((int) random(palette.size())).toARGB();

    physics.addParticle(vp);
    physics.addBehavior(abh);

    this.broken = false;
    this.dead = false;
  }

  void update() {

    if (this.dead) {
      return;
    }

    checkBreak();

    if (broken) {
      if (this.transparency > 5) {
        this.transparency -= 2;
      } 
      else {
        faces.clear();
        this.dead = true;
      }

      for (int i = 0; i < faces.size(); i++) {
        PVector n = faceNormals.get(i);
        PVector targetDir = PVector.mult(n, speed[i]);
        PVector[] f = faces.get(i);
        f[0].add(targetDir);
        f[1].add(targetDir);
        f[2].add(targetDir);
        faces.set(i, f);
        PVector c = internal.get(i); 
        c.add(targetDir);
        internal.set(i, c);
      }
    } 
    else {
      pos.set(vp.x, vp.y, vp.z);
    }
  }

  void display() {

    if (this.dead) {
      return;
    }

    pushMatrix();
    
    translate(this.pos.x, this.pos.y, this.pos.z);
    scale(this.radius);
    
    strokeWeight(1 / this.radius);

    beginShape(TRIANGLES);

    float r = (float)(red(fill)) / 255.0;
    float g = (float)(green(fill)) / 255.0;
    float b = (float)(blue(fill)) / 255.0;
    

    for (int i = 0; i < faces.size(); i++) {
      PVector[] f = faces.get(i);
      PVector c = internal.get(i);

      vertex(f[0].x, f[0].y, f[0].z);
      vertex(f[1].x, f[1].y, f[1].z);
      vertex(f[2].x, f[2].y, f[2].z);

      vertex(f[0].x, f[0].y, f[0].z);
      vertex(f[1].x, f[1].y, f[1].z);
      vertex(c.x, c.y, c.z);

      vertex(f[0].x, f[0].y, f[0].z);
      vertex(c.x, c.y, c.z);
      vertex(f[2].x, f[2].y, f[2].z);

      vertex(c.x, c.y, c.z);
      vertex(f[1].x, f[1].y, f[1].z);
      vertex(f[2].x, f[2].y, f[2].z);
    }
    endShape();
    popMatrix();
  }

  void checkBreak() {
    // collision with ray check!
    if (mousePressed && mousePicker.enabled) {
      PVector rp = PVector.sub(mousePicker.getOrigin(), pos);
      PVector mouseRay = mousePicker.getRay();
      Ray3D ray = new Ray3D(new Vec3D(rp.x, rp.y, rp.z), new Vec3D(mouseRay.x, mouseRay.y, mouseRay.z)); 
      if ( proxy.intersectRay(ray) != null) {
        this.explode();
      }
    }
  }

  void checkCollision(PVector p) {
    // collision with a point
    
    PVector p2 = PVector.sub(p, pos);
    
    if (proxy.containsPoint(new Vec3D(p2.x, p2.y, p2.z))) {
      this.explode();
    }
  }

  void explode() {
    this.broken = true;
    //this.reset();
    physics.removeParticle(vp);
    physics.removeBehavior(abh);
    start = frameCount;
  }

  // sample the unit sphere with uniform or biased distribution
  void samplePoints() {
    float u;
    float v;
    Vec2D pSpherical;
    Vec3D pXYZ;

    FloatRange samplerU = new FloatRange(0, 1.0f);//new BiasedFloatRange(0, 1, biasUV.x, 0.5f);
    FloatRange samplerV = new FloatRange(0, 1.0f);//new BiasedFloatRange(0, 1, biasUV.y, 0.5f);

    this.qPoints = new Point3d[this.numPoints];

    for (int i = 0; i < this.numPoints; i++) {
      u = samplerU.pickRandom();
      v = samplerV.pickRandom();
      pSpherical = uvToSpherical(u, v);
      pXYZ = sphericalToXYZ(pSpherical.x, pSpherical.y, 1.0);
      this.qPoints[i] = new Point3d(pXYZ.x, pXYZ.y, pXYZ.z);
    }
  }

  // compute the Delaunay triangulation of the points with the hull method
  void computeDelaunay() {
    QuickHull3D hull = new QuickHull3D();
    hull.build (this.qPoints);
    qVertices = hull.getVertices();
    qFaceIndices = hull.getFaces();

    for (int i = 0; i < qFaceIndices.length; i++) {
      addFace(qFaceIndices[i]);
    }
  }

  void addFace(int[] qFace) {
    PVector[] f = new PVector[qFace.length];
    for (int k = 0; k < qFace.length; k++) { 
      Point3d p = qVertices[qFace[k]];
      f[k] = new PVector((float)p.x, (float)p.y, (float)p.z);
    }

    PVector n = new PVector();
    PVector.cross(PVector.sub(f[1], f[0]), PVector.sub(f[2], f[0]), n);
    n.normalize();
    faceNormals.add(n);
    faces.add(f);
    PVector c = PVector.mult(n, random(-0.1, -1.0));
    internal.add(c);
  }
}

Vec2D uvToSpherical(float u, float v) {
  float theta = 2 * PI * u;
  float phi = acos(2 * v - 1);
  return new Vec2D(theta, phi);
}

Vec2D sphericalToUV(float theta, float phi) {
  float u = theta / (2 * PI);
  float v = 0.5f * (cos(phi) + 1);
  return new Vec2D(u, v);
}

Vec3D sphericalToXYZ(float theta, float phi, float r) {
  float x = r * cos(theta) * sin(phi);
  float y = r * sin(theta) * sin(phi);
  float z = r * cos(phi);
  return new Vec3D(x, y, z);
}

Vec2D xyzToSpherical(float x, float y, float z, float r) {
  float theta = atan2(y, x);
  float phi = acos(z / r);
  return new Vec2D(theta, phi);
}

