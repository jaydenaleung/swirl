/*

Author: Jayden Leung
AI Help Acknowledged. AP CS A Tutor on ChatGPT and GPT-5 + Github Copilot for help with syntax and debugging.
Date: September 17, 2025
Name: Swirl
Description: This program generates art using Perlin noise to create a swirl effect responding to mouse movement and position.

NOTES FOR THE USER:
- Test out different values for the diameter! (Only change the diameter, not the radius.) I've found 1.8 to be quite nice.
- You may notice that the FPS is quite low (about 18 fps). This is a natural response for a larger canvas, but because the swirling is slow, the effects of the low frame rate is not very noticeable.
- The small canvas size is also intentional. This is both to keep the FPS high enough and to keep the diameter low so the swirling doesn't become too beady. (If the diameter is kept low in a large canvas, the canvas will take a long time to fill with particles initially. Increasing the number of particles will drastically reduce FPS.)
- The previous note also explains why there are white dots initially. While they can be removed, I think it provides a nice effect.
- There are a few toggle options such as enableSortedSpawning that changes the way the canvas looks.

*/

/*

Possible Extensions of This Project, If I Had More Time:
- Add rotational momentum other than just linear from oblique collisions
- Increase efficiency even more to increase maximum screen size and particle count
- Add other modes or the ability to add paint in.

*/


float diameter = 2.0;
float radius = diameter/2.0;

int n = 8000; // # of particles

// per-channel offsets for RGB initial Perlin noise color generation
float rOffX = random(1000); float rOffY = random(1000); float rScale = random(0.005, 0.02);
float gOffX = random(1000); float gOffY = random(1000); float gScale = random(0.005, 0.02);
float bOffX = random(1000); float bOffY = random(1000); float bScale = random(0.005, 0.02);

float leak = 10.0; // how far outside the screen the particles can go before bouncing back
boolean enableSortedSpawning = false; // particles are generated in neat rows. Set true by default for color field generation. Set false for debugging or randomizing colors.
boolean smooth = false; // Perlin noise generation uses a third dimension t which makes the changing of the color smoother

Particle[] particles = new Particle[n+1]; // +1 for mouse particle
Particle mp = new Particle(n); // make a Particle at a mouse and put in random index
color[] initialColors;

ArrayList<Particle>[][] grid;
int colSize,rowSize;
int cols = 10; // incremented by 2 later
int rows = 10; // incremented by 2 later

float textSize;

float b = 1.010; // friction coefficient - divides the velocity of each particle by this every frame


// Gridding - allows collisionCheck with only the particles in the main particle's box and the ones surrounding that box
// Make grid of rows and columns as a 2D ArrayList, rows and columns are the height and width divided by 10. Then - Compute which particles are in which box at the start of each loop function and at the start of setup() but after initParticles. 
void initGrid() {
  grid = new ArrayList[cols][rows];
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = new ArrayList<Particle>();
    }
  }
}

void clearGrid() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j].clear();
    }
  }
}

void assignGrid(Particle[] particles) {
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    int cx = (int)(constrain(p.pos.x,0,width)/colSize); // particle's column index - the first column is 0, the second is 1, etc.
    int cy = (int)(constrain(p.pos.y,0,width)/rowSize);

    grid[cx][cy].add(p);
  }
}

// Physics calculations
boolean isColliding(Particle a, Particle b) {
  float dx = b.pos.x-a.pos.x; // x diff between a and b
  float dy = b.pos.y-a.pos.y;
  return dx*dx+dy*dy < diameter*diameter; // pythagorean theorem without sqrt()
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
  void checkCollision() {
    collidingWith.clear();

    // Retrieve the column and row of the particle in the grid mathematically instead of using .indexOf - which is more computationally intensive
    int cx = (int)(this.pos.x/colSize); // particle's column index - the first column is 0, the second is 1, etc.
    int cy = (int)(this.pos.y/rowSize);

    int[][] boxes = {{cx,cy},{cx-1,cy-1},{cx,cy-1},{cx+1,cy-1},{cx-1,cy},{cx+1,cy},{cx-1,cy+1},{cx,cy+1},{cx+1,cy+1}}; // 3x3 grid around the particle's box (note: this array doesn't strictly store boxes; it store their x and y box indices)

    for (int i = 0; i < boxes.length; i++) {
      int boxXInQuestion = boxes[i][0];
      int boxYInQuestion = boxes[i][1];

      if (boxXInQuestion >= 0 && boxXInQuestion < cols && boxYInQuestion >= 0 && boxYInQuestion < rows) { // prevents array index out of range
        for (int j = 0; j < grid[boxXInQuestion][boxYInQuestion].size(); j++) {
          Particle pInQuestion = grid[boxXInQuestion][boxYInQuestion].get(j); // the particle we're checking if it's colliding with our current particle

          if (pInQuestion != this && isColliding(this, pInQuestion)) {
            collidingWith.add(pInQuestion);
          }
        }
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

  loadPixels();
  initialColors = pixels.clone();
}

void drawParticles(Particle[] particles) {
  for (int i = 0; i < particles.length-1; i++) { // particles.length-1 prevents mouse particle from being drawn
    Particle p = particles[i];
    
    // If using points
    stroke(p.col); // used for point(), instead of using fill()
    strokeWeight(p.d);
    point(p.pos.x,p.pos.y);

    // // If using circles
    // fill(p.col); // used for point(), instead of using fill()
    // circle(p.pos.x,p.pos.y,p.d);
  }
}

void drawBackground() {
  loadPixels();
  pixels = initialColors;
  updatePixels();
}

void masterUpdate(Particle[] particles) {
  clearGrid();
  assignGrid(particles); // rebuild the grid
  
  if (mousePressed) {
    // update mp.pos and mp.vel before calculating collisions
    mp.ppos = mp.pos.copy();
    mp.pos = new PVector(mouseX, mouseY);

    PVector mv = PVector.sub(mp.pos,mp.ppos).div(3);
    mp.vel = mv;
  }

  // update all positions according to the vector, then redraw all circles according to the list
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.checkCollision();
  }
  for (int i = 0; i < particles.length; i++) {
    Particle p = particles[i];
    p.vectorUpdate();
    if (!(p == mp)) { p.positionUpdate(); }
  }
}

// Auxiliary functions
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
    particles[i].vel.div(b); // a good balance between friction and ability to move. Can be thought of as the "viscosity" of the "paint". Slows each particle down every frame.
  }
}

void renderInstructions() {
  float x = 10;
  float y = height-textSize-15;
  float w = textWidth("Click and drag the mouse"); // max text width
  float h = textSize*2+5;

  float a = 255-(millis()/10-500); // after 5 seconds, fade out the text background
  
  noStroke();
  fill(255,constrain(a,0,255));
  rect(x-5,y-18,w+10,h+8,3); // offset from text position to create a rounded text box background
  fill(0);
  text("Click and drag the mouse\nto create a color swirl.", x, y); // instructions (text wrapped)
}


///////////////////////

void setup() {
  size(250, 250, P2D); // P2D activates GPU renderer
  frameRate(60);

  // noSmooth();
  noStroke();
  strokeCap(ROUND); // points seem round (use PROJECT for square)
  blendMode(BLEND);

  colSize = (int)width / cols;
  rowSize = (int)height / rows;
  cols += 2; // increment to account for the remainder of colSize and rowSize being truncated
  rows += 2;

  background(255);

  textSize = height/15;
  fill(0); // black text
  textSize(textSize);

  initParticles(particles);
  initGrid();
  assignGrid(particles);
  // randomizeVelocity(particles); // may remove later
  drawParticles(particles);
}

void draw() {
  // drawBackground(); // might help with clearing white dots - but not when tested, so not used
  masterUpdate(particles);
  friction(particles);
  preventOutOfBounds(particles); // may remove later
  drawParticles(particles);

  renderInstructions();
  
  print(frameRate);
}