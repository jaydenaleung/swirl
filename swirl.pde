/*

Author: Jayden Leung
AI Help Acknowledged. AP CS A Tutor on ChatGPT and GPT-5 + Github Copilot for help with syntax and debugging.
Date: September 17, 2025
Name: Swirl
Description: This program generates art using Perlin noise to create a swirl effect responding to mouse movement and position.

*/


// Global variables
int x = 0;
int y = 0;
int d = 5; // diameter

// set paramters for 2D Perlin noise, generate random initial seeds for RGB values
float scale = 0.01;
float rSeedX = random(1000), rSeedY = random(1000);
float gSeedX = random(1000), gSeedY = random(1000);
float bSeedX = random(1000), bSeedY = random(1000);

// Base seed offsett for mouse computation, dependent on x, y, r, g, b
float baseSeedOffsetXMultR = random(0,0.1);
float baseSeedOffsetXAddR = random(0,100);
float baseSeedOffsetYMultR = random(0,0.1);
float baseSeedOffsetYAddR = random(0,100);
float baseSeedOffsetXMultG = random(0,0.1);
float baseSeedOffsetXAddG = random(0,100);
float baseSeedOffsetYMultG = random(0,0.1);
float baseSeedOffsetYAddG = random(0,100);
float baseSeedOffsetXMultB = random(0,0.1);
float baseSeedOffsetXAddB = random(0,100);
float baseSeedOffsetYMultB = random(0,0.1);
float baseSeedOffsetYAddB = random(0,100);

// Functions

void generateParticles() {
  boolean redrawing = true;

  // Reset x/y values
  x = 0; y = 0;
  
  // Update values based on mouse position
  rSeedX = mouseX*baseSeedOffsetXMultR+baseSeedOffsetXAddR; rSeedY = mouseY*baseSeedOffsetYMultR+baseSeedOffsetYAddR;
  gSeedX = mouseX*baseSeedOffsetXMultG+baseSeedOffsetXAddG; gSeedY = mouseY*baseSeedOffsetYMultG+baseSeedOffsetYAddG;
  bSeedX = mouseX*baseSeedOffsetXMultB+baseSeedOffsetXAddB; bSeedY = mouseY*baseSeedOffsetYMultB+baseSeedOffsetYAddB;

  while (redrawing) {
    // Recompute variables
    float nx = x*scale;
    float ny = y*scale;
    float r = noise(nx + rSeedX, ny + rSeedY) * 255;
    float g = noise(nx + gSeedX, ny + gSeedY) * 255;
    float b = noise(nx + bSeedX, ny + bSeedY) * 255;
    
    // Redraw circles
    fill(r,g,b);
    circle(x,y,d);
    
    x += d;
    if (x > width) {
      x = 0;
      y += d;
    }

    if (y > height) {
      redrawing = false;
    }
  }
}

/////////////////////////////////////////////////

void setup() {
  size(500,500);
  noStroke();
  frameRate(60); // slow down frame rate to see changes
}

void draw() {
  background(255);
  generateParticles();
}
