/*

Author: Jayden Leung
AI Help Acknowledged. AP CS A Tutor on ChatGPT and GPT-5 + Github Copilot for help with syntax and debugging.
Date: September 17, 2025
Name: Swirl
Description: This program generates art using Perlin noise to create a swirl effect responding to mouse movement and position.

*/

float diameter = 1.0;
float radius = diameter/2.0;

int n = 10000; // # of particles

// per-channel offsets for RGB initial Perlin noise color generation
float rOffX = random(1000); float rOffY = random(1000); float rScale = random(0.005, 0.02);
float gOffX = random(1000); float gOffY = random(1000); float gScale = random(0.005, 0.02);
float bOffX = random(1000); float bOffY = random(1000); float bScale = random(0.005, 0.02);

float leak = 2.0; // how far outside the screen the particles can go before bouncing back
boolean enableSortedSpawning = false; // particles are generated in neat rows. Set true by default for color field generation. Set false for debugging or randomizing colors.
boolean smooth = false; // Perlin noise generation uses a third dimension t which makes the changing of the color smoother

Particle[] particles = new Particle[n+1]; // +1 for mouse particle
Particle mp = new Particle(n); // make a Particle at a mouse and put in random index

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

// Perlin noise color-generation
void generateColor(Particle p) {
  float r,g,b;

  if (smooth) {
    float t = millis() * 0.0001;  // smooth time animation - use for smoother gradient
    r = 255 * noise(p.initx * rScale + rOffX, p.inity * rScale + rOffY, t);
    g = 255 * noise(p.initx * gScale + gOffX, p.inity * gScale + gOffY, t);
    b = 255 * noise(p.initx * bScale + bOffX, p.inity * bScale + bOffY, t);
  } else {
    r = 255 * noise(p.initx * rScale + rOffX, p.inity * rScale + rOffY);
    g = 255 * noise(p.initx * gScale + gOffX, p.inity * gScale + gOffY);
    b = 255 * noise(p.initx * bScale + bOffX, p.inity * bScale + bOffY);
  }

  p.col = color(r,g,b);
}

// Main class
class Particle {
  PVector pos, vel, ppos;
  float initx,inity;
  float d;
  color col;
  float roff,goff,boff;
  boolean colliding;
  ArrayList<Particle> collidingWith; // list of particles this particle is colliding with
  int index;

  Particle(int ind) {
    index = ind;
    if (enableSortedSpawning) {
      if (index < width) { // first row of screen
        initx = index;
        inity = 0;
      } else {
        initx = index % width; // returns the x value in the next row
        inity = (index-initx)/width; // returns the row number
      }

      // radius increment since Processing writes the center at its point
      initx += radius;
      inity += radius;
      pos = new PVector(initx,inity);
    } else {
      pos = new PVector(random(0.0,width),random(0.0,height));
      initx = pos.x;
      inity = pos.y;
    }

    ppos = new PVector(0.0,0.0);
    vel = new PVector(0.0,0.0);
    d = diameter;

    roff = random(1000);
    boff = random(1000);
    goff = random(1000);
    generateColor(this);

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

  // init the mouse particle
  mp.pos = new PVector(mouseX,mouseY);
  mp.col = color(0, 0, 0, 0);
  // mp.d = 1;
  particles[n] = mp; // add to array
}

void drawParticles(Particle[] particles) {
  for (int i = 0; i < particles.length-1; i++) { // particles.length-1 prevents mouse particle from being drawn
    Particle p = particles[i];
    stroke(p.col); // used for point(), instead of using fill()
    strokeWeight(p.d);
    point(p.pos.x,p.pos.y);
  }
}

void masterUpdate(Particle[] particles) {
  // update mp.pos and mp.vel before calculating collisions
  mp.ppos = mp.pos.copy();
  mp.pos = new PVector(mouseX, mouseY);

  PVector mv = PVector.sub(mp.pos,mp.ppos).div(5);
  mp.vel = mv;

  // update all positions according to the vector, then redraw all circles according to the list
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.checkCollision(particles);
  }
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.vectorUpdate();
    if (!(p == mp)) { p.positionUpdate(); }
  }
}

// Temporary functions
void preventOutOfBounds(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    if ((particles[i].pos.x-radius)+leak < 0 || (particles[i].pos.x+radius)-leak > width) {
      particles[i].vel.x *= -1;
    }
    if ((particles[i].pos.y-radius)+leak < 0 || (particles[i].pos.y+radius)-leak > height) {
      particles[i].vel.y *= -1;
    }
  }
}

void randomizeVelocity(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    particles[i].vel = new PVector(random(0.5,10.0), random(0.5,10.0));
  }
}

void friction(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    particles[i].vel.div(1.1);
  }
}

///////////////////////

void setup() {
  size(88, 88, P2D); // P2D activates GPU renderer
  frameRate(60);

  noSmooth();
  noStroke();
  strokeCap(ROUND); // points seem round (use PROJECT for square)

  initParticles(particles);
  // randomizeVelocity(particles); // may remove later
  drawParticles(particles);
}

void draw() {
  background(255);
  masterUpdate(particles);
  friction(particles);
  preventOutOfBounds(particles); // may remove later
  drawParticles(particles);
}