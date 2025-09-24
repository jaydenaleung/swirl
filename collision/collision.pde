int diameter = 5;

class Particle {
  PVector pos, vel;
  int d;
  color col; // placeholder
  boolean colliding;

  Particle() {
    pos = new PVector(random(width),random(height)); // placeholder
    vel = new PVector(0,0);
    d = diameter;
    col = color(random(255),random(255),random(255));
    colliding = false;
  }

  // method checking if colliding by coords, if yes, then set colliding to true and vice versa
  void checkCollision() {
    for (int i = 0; i < particles.length; i++) {
      Particle pInQuestion = particles[i]; // the particle we're checking if it's colliding with our current particle
      if (dist(pos.x,pos.y,pInQuestion.pos.x,pInQuestion.pos.y) < diameter) {
        colliding = true;
      }
    }
  }

  // method checking state of colliding, if yes, then recompute the vector, if no, don't do anything
  void particleUpdate() {

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
}



///////////////////////



void setup() {
    size(500, 500);
    frameRate(60);
    x = width/2;
    y = height/2;
}

int x;
int y;
int d = 100;

PVector v_ball = new PVector(0,0);
PVector v_mouse = new PVector(0,0); // in pixels per frame

boolean collision = false;

void draw() {
    background(255);
    fill(126,2,58);

    v_mouse.set(mouseX-pmouseX, mouseY-pmouseY, 0);
    println(v_mouse.x,v_mouse.y);

    if (dist(mouseX,mouseY,x,y) < d/2) { 
        collision = true;
        println("Collision");
    }

    if (collision) {
        v_ball.set((int)(v_mouse.x/2),(int)(v_mouse.y/2),0);
        x += v_ball.x;
        y += v_ball.y;
        collision = false;
    }

    /* AI GENERATED, REMOVE LATER */
    float restitution = 1.0; // 1.0 = perfectly elastic, <1 = energy loss
    int half = d/2;
    if (x - half < 0) {
      x = half;
      v_ball.x *= -restitution;
    }
    if (x + half > width) {
      x = width - half;
      v_ball.x *= -restitution;
    }
    if (y - half < 0) {
      y = half;
      v_ball.y *= -restitution;
    }
    if (y + half > height) {
      y = height - half;
      v_ball.y *= -restitution;
    }

    //update circles
    x += v_ball.x;
    y += v_ball.y;

    circle(x,y,d);
}