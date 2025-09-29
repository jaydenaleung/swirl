float diameter = 10.0;
float radius = diameter/2.0;
int n = 1000; // # of particles

boolean enableSortedSpawning = false; // particles are generated in neat rows. Set true by default for color field generation. Set false for debugging or randomizing colors.

Particle[] particles = new Particle[n];

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
  } else {
    v1p = v1;
    v2p = v2;
  }
  return new PVector[] {v1p, v2p};
}

// Main class
class Particle {
  PVector pos, vel;
  float d;
  color col; // placeholder
  boolean colliding;
  ArrayList<Particle> collidingWith; // list of particles this particle is colliding with
  int index;

  Particle(int ind) {
    index = ind;
    if (enableSortedSpawning) {
      int initx;
      int inity;
      if (index < width) { // first row of screen
        initx = index;
        inity = 0;
      } else {
        initx = index % width; // returns the x value in the next row
        inity = (index-initx)/width; // returns the row number
      }

      pos = new PVector(initx+radius,inity+radius); // radius increment since Processing writes the center at its point
    } else {
      pos = new PVector(random(0.0,width),random(0.0,height));
    }
    vel = new PVector(0.0,0.0);
    d = diameter;
    col = color(random(255),random(255),random(255));

    colliding = false;
    collidingWith = new ArrayList<Particle>();
  }

  // method checking if colliding by coords, if yes, then set colliding to true and vice versa
  void checkCollision(Particle[] particles) {
    collidingWith.clear();
    for (int i = 0; i < particles.length; i++) {
      Particle pInQuestion = particles[i]; // the particle we're checking if it's colliding with our current particle
      if (pInQuestion != this && isColliding(this, pInQuestion)) {
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
        
        positionalSeperation(this,pInQuestion);
      }
    }
  }

  void positionalSeperation(Particle p, Particle pIQ) {
    if (isColliding(p,pIQ)) {
      PVector n = PVector.sub(pos, pIQ.pos); // vector pointing from pIQ to p
      if (n.magSq() == 0) { // degenerate case where positions are the same, then pick a random direction to push them apart
        n.set(1,0,0);
      } else {
        n.normalize(); // turn it into a unit (normalized) vector
      }
      float overlap = diameter - PVector.dist(pos,pIQ.pos); // amount that it overlaps, protected by isColliding to be > 0
      float half = overlap/2.0;
      pos.add(PVector.mult(n, half)); // push the particle out along vector n by half of the overlap (symmetric seperation)
      pIQ.pos.sub(PVector.mult(n, half)); // push the other particle out along vector n by half of the overlap (symmetric seperation)
    }
  }

  // Recompute the position based on the vectors
  void positionUpdate() {
    pos.x += vel.x;
    pos.y += vel.y;
  }
}

// Main functions
void initParticles(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    Particle p = new Particle(i);
    particles[i] = p;
  }
}

void drawParticles(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    stroke(p.col); // used for point(), instead of using fill()
    strokeWeight(p.d);
    point(p.pos.x,p.pos.y);
  }
}

void masterUpdate(Particle[] particles) {
// update all positions according to the vector, then redraw all circles according to the list
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.checkCollision(particles);
  }
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.vectorUpdate();
    p.positionUpdate();
  }
}

// Temporary functions
void preventOutOfBounds(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    if (particles[i].pos.x-radius < 0 || particles[i].pos.x+radius > width) {
      particles[i].vel.x *= -1;
    }
    if (particles[i].pos.y-radius < 0 || particles[i].pos.y+radius > height) {
      particles[i].vel.y *= -1;
    }
  }
}

void randomizeVelocity(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    particles[i].vel = new PVector(random(0.5,10.0), random(0.5,10.0));
  }
}

///////////////////////

void setup() {
  size(500, 500);
  frameRate(60);

  noSmooth();
  noStroke();
  strokeCap(ROUND); // points seem round (use PROJECT for square)

  initParticles(particles);
  randomizeVelocity(particles); // may remove later
  drawParticles(particles);
}

void draw() {
  background(255);
  masterUpdate(particles);
  preventOutOfBounds(particles); // may remove later
  drawParticles(particles);
}