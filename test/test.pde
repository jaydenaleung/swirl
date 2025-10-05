float diameter = 1.0;
float radius = diameter/2.0;
float diameterSq = diameter * diameter; // cache squared distance

int n = 10000; // can now handle much more particles

// Optimization: use primitive arrays instead of PVector objects
float[] px = new float[n+1];
float[] py = new float[n+1];
float[] vx = new float[n+1];
float[] vy = new float[n+1];
int[] colors = new int[n+1];

// Simple spatial grid for collision optimization
int gridSize = 10;
int gridCols, gridRows;
ArrayList<Integer>[] grid;

// Physics - optimized collision detection (no sqrt)
boolean isCollidingFast(int a, int b) {
  float dx = px[a] - px[b];
  float dy = py[a] - py[b];
  return (dx*dx + dy*dy) < diameterSq;
}

// Optimized collision response
void resolveCollision(int a, int b) {
  float dx = px[b] - px[a];
  float dy = py[a] - py[b];
  float distSq = dx*dx + dy*dy;
  
  if (distSq >= diameterSq) return;
  
  float dist = sqrt(distSq);
  if (dist == 0) { dx = 1; dy = 0; dist = 1; }
  
  float nx = dx / dist;
  float ny = dy / dist;
  
  // Separate particles
  float overlap = diameter - dist;
  float sep = overlap * 0.5f;
  px[a] -= nx * sep;
  py[a] -= ny * sep;
  px[b] += nx * sep;
  py[b] += ny * sep;
  
  // Velocity response
  float rvx = vx[b] - vx[a];
  float rvy = vy[b] - vy[a];
  float velAlongNormal = rvx * nx + rvy * ny;
  
  if (velAlongNormal < 0) {
    float restitution = 0.9f;
    float impulse = -(1 + restitution) * velAlongNormal * 0.5f;
    float ix = nx * impulse;
    float iy = ny * impulse;
    
    vx[a] -= ix;
    vy[a] -= iy;
    vx[b] += ix;
    vy[b] += iy;
  }
}

// Spatial grid optimization
void initGrid() {
  gridCols = width / gridSize + 1;
  gridRows = height / gridSize + 1;
  grid = new ArrayList[gridCols * gridRows];
  for (int i = 0; i < grid.length; i++) {
    grid[i] = new ArrayList<Integer>();
  }
}

void updateGrid() {
  // Clear grid
  for (ArrayList<Integer> cell : grid) {
    cell.clear();
  }
  
  // Assign particles to grid cells
  for (int i = 0; i < n; i++) {
    int gx = constrain((int)(px[i] / gridSize), 0, gridCols-1);
    int gy = constrain((int)(py[i] / gridSize), 0, gridRows-1);
    grid[gy * gridCols + gx].add(i);
  }
}

// Fast collision detection using spatial grid
void handleCollisions() {
  updateGrid();
  
  for (int gy = 0; gy < gridRows; gy++) {
    for (int gx = 0; gx < gridCols; gx++) {
      ArrayList<Integer> cell = grid[gy * gridCols + gx];
      
      // Check within cell
      for (int i = 0; i < cell.size()-1; i++) {
        for (int j = i+1; j < cell.size(); j++) {
          resolveCollision(cell.get(i), cell.get(j));
        }
      }
      
      // Check adjacent cells (right and down only to avoid duplicates)
      if (gx < gridCols-1) {
        ArrayList<Integer> rightCell = grid[gy * gridCols + (gx+1)];
        for (int a : cell) {
          for (int b : rightCell) {
            resolveCollision(a, b);
          }
        }
      }
      
      if (gy < gridRows-1) {
        ArrayList<Integer> downCell = grid[(gy+1) * gridCols + gx];
        for (int a : cell) {
          for (int b : downCell) {
            resolveCollision(a, b);
          }
        }
      }
    }
  }
}

// Optimized color generation
void generateColors() {
  float t = smooth ? millis() * 0.0001f : 0;
  
  for (int i = 0; i < n; i++) {
    float x = px[i];
    float y = py[i];
    
    float r = 255 * noise(x * rScale + rOffX, y * rScale + rOffY, t);
    float g = 255 * noise(x * gScale + gOffX, y * gScale + gOffY, t + 10);
    float b = 255 * noise(x * bScale + bOffX, y * bScale + bOffY, t + 20);
    
    colors[i] = color(r, g, b);
  }
}

// Initialization
void initParticles() {
  for (int i = 0; i < n; i++) {
    if (enableSortedSpawning) {
      px[i] = (i % width) + radius;
      py[i] = (i / width) + radius;
    } else {
      px[i] = random(radius, width - radius);
      py[i] = random(radius, height - radius);
    }
    
    vx[i] = 0;
    vy[i] = 0;
  }
  
  // Mouse particle
  px[n] = mouseX;
  py[n] = mouseY;
  vx[n] = 0;
  vy[n] = 0;
  colors[n] = color(255, 0, 0); // red mouse particle
  
  generateColors();
}

// Optimized drawing
void drawParticles() {
  for (int i = 0; i < n; i++) {
    stroke(colors[i]);
    strokeWeight(diameter);
    point(px[i], py[i]);
  }
}

// Main update loop
void masterUpdate() {
  // Update mouse particle
  float mpx = mouseX;
  float mpy = mouseY;
  vx[n] = (mpx - px[n]) * 0.2f;
  vy[n] = (mpy - py[n]) * 0.2f;
  px[n] = mpx;
  py[n] = mpy;
  
  // Handle collisions using spatial grid
  handleCollisions();
  
  // Update positions
  for (int i = 0; i < n; i++) {
    px[i] += vx[i];
    py[i] += vy[i];
  }
}

void preventOutOfBounds() {
  for (int i = 0; i < n; i++) {
    if (px[i] < radius || px[i] > width - radius) {
      vx[i] *= -1;
      px[i] = constrain(px[i], radius, width - radius);
    }
    if (py[i] < radius || py[i] > height - radius) {
      vy[i] *= -1;
      py[i] = constrain(py[i], radius, height - radius);
    }
  }
}

void friction() {
  for (int i = 0; i < n; i++) {
    vx[i] *= 0.99f;
    vy[i] *= 0.99f;
  }
}

// Global variables for color
float rOffX = random(1000), rOffY = random(1000), rScale = random(0.005, 0.02);
float gOffX = random(1000), gOffY = random(1000), gScale = random(0.005, 0.02);
float bOffX = random(1000), bOffY = random(1000), bScale = random(0.005, 0.02);
boolean enableSortedSpawning = false;
boolean smooth = false;

void setup() {
  size(200, 200, P2D); // Larger canvas for better performance testing
  frameRate(60);
  
  noSmooth();
  strokeCap(ROUND);
  
  initGrid();
  initParticles();
}

void draw() {
  background(255);
  
  masterUpdate();
  friction();
  preventOutOfBounds();
  
  if (smooth && frameCount % 10 == 0) { // Update colors less frequently
    generateColors();
  }
  
  drawParticles();
  
  // Performance monitoring
  if (frameCount % 60 == 0) {
    println("FPS: " + frameRate + " Particles: " + n);
  }
}