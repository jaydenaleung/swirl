# Swirl - Collision-Based Perlin Noise-Generated Color Field

## A simulated paint bucket. Made for my AP CS A Unit 2 Conditionals and Loops project.

**Play it here: [loliipoppi.itch.io/swirl](url)**

### Concept

I was interested in coding natural systems, so I decided on the intersection between natural motion swirls and physics. See picture below for what I was envisioning.

<img width="455" height="331" alt="Screenshot 2025-09-29 at 8 48 30 PM" src="https://github.com/user-attachments/assets/e498e55a-de70-43dd-808c-2e587c920943" />

### Methods

I used a single class Particle and an array of Particles to generate them on the screen. The particles are 1 px in diameter and fill the screen. Initially, a three-dimensional Perlin noise function based on x position, y position, and, optionally, time for smoothness, generates the color field of particles. Collision-based physics - including oblique collisions - manage interactions between particles. The mouse can also interact with these particles.

<img width="300" height="300" alt="Screenshot 2025-09-29 at 8 51 51 PM" src="https://github.com/user-attachments/assets/73a58859-4115-47ef-8a6f-40a5e2b8d42b" />
