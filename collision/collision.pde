int diameter = 5;

// Physics calculations
boolean isColliding(Particle a, Particle b) {
  return dist(a.pos.x,a.pos.y,b.pos.x,b.pos.y) < diameter;
}

PVector[] computeCollisionVector(PVector p1, PVector v1, PVector p2, PVector v2) {
  // E IN EQUATION ASSUMED TO BE 1; float e = 0.9; // coefficient of restitution (change this to simulate different conditions; 0.0-1.0 elasticity)
  
  // equation for the normal
  PVector n = PVector.sub(p1,p2).normalize();
  PVector rel = PVector.sub(v1,v2);
  float vrel = rel.dot(n);

  PVector v1p = new PVector(0,0);
  PVector v2p = new PVector(0,0);

  if (vrel < 0) { // else (moving apart) do nothing
    v1p = PVector.sub(v1,PVector.mult(n,vrel));
    v2p = PVector.add(v2,PVector.mult(n,vrel));
  }
  return new PVector[] {v1p, v2p};
}


class Particle {
  PVector pos, vel;
  int d;
  color col; // placeholder
  boolean colliding;
  ArrayList<Particle> collidingWith; // list of particles this particle is colliding with

  Particle() {
    pos = new PVector(random(width),random(height)); // placeholder
    vel = new PVector(0,0);
    d = diameter;
    col = color(random(255),random(255),random(255));

    colliding = false;
    collidingWith = new ArrayList<Particle>();
  }

  // method checking if colliding by coords, if yes, then set colliding to true and vice versa
  void checkCollision() {
    collidingWith.clear();
    for (int i = 0; i < particles.length; i++) {
      Particle pInQuestion = particles[i]; // the particle we're checking if it's colliding with our current particle
      if (isColliding(this, pInQuestion)) {
        collidingWith.add(pInQuestion);
      }
    }
    if (collidingWith.size() > 0) { colliding = true; } else { colliding = false; }
  }

  // method checking state of colliding, if yes, then recompute the vector, if no, don't do anything
  void vectorUpdate() {
    if (colliding) {
      for (int i = 0; i < collidingWith.size(); i++) {
        Particle pInQuestion = collidingWith.get(i);
        PVector[] newVels = computeCollisionVector(this.pos,this.vel,pInQuestion.pos,pInQuestion.vel);
        vel = newVels[0];
        pInQuestion.vel = newVels[1];
        pInQuestion.collidingWith.remove(this); // remove this object from the other particles collision list so that it won't compute the vector twice
      }
      positionUpdate(); // update positions acc to vector
    }
  }

  // Recompute the position based on the vectors
  void positionUpdate() {
    pos.x += vel.x;
    pos.y += vel.y;
  }
}

Particle[] particles = new Particle[250000];

void initParticles() {
  for (int i = 0; i < 250000; i++) {
    Particle p = new Particle();
    particles[i] = p;
  }
}

void masterUpdate() {
// update all positions according to the vector, then redraw all circles according to the list
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.checkCollision();
  }
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.vectorUpdate();
  }
}

///////////////////////

void setup() {
  size(500, 500);
  frameRate(60);

  initParticles();
}

void draw() {
  background(255);
  masterUpdate();
}