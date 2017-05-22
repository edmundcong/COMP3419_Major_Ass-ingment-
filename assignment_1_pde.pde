import processing.video.*; //<>// //<>// //<>// //<>// //<>// //<>//
Movie myMovie;
Movie backgoundMovie;

// Background removing colour threshholds
int BLUE_min = 60; // between 90 and 150
int BLUE_max = 210; // between 90 and 150
int GREEN = 170;
int RED = 160;
// monkey limb colour thresholds
int MONKEY_RED = 165; // monkey limb red value
int MONKEY_GREEN = 160;
int MONKEY_BLUE = 150;

// movie data structures

// background
int background_frames = 532;
int background_counter = 0;
PImage[] background_movie = new PImage[background_frames];

// foreground
int foreground_frames = 955; 
int foreground_counter = 0;

// data structure of 5 sets of coordinates to track limbs through frames
int[][][] red_markers = new int[foreground_frames][5][2];

// flags
boolean new_frame = false; // to render new frame without background
boolean wrapped = false;
boolean monkey_kick = false;

// temp variables
PImage temp_image;
PImage background_temp;

// variables to keep count
//int wrapped_background_counter = 0;
PVector location;  // Location of shape
PVector velocity;  // Velocity of shape
PVector gravity;   // Gravity acts at the shape's acceleration

void setup() {
  size(568, 320);
  // background movie set up
  backgoundMovie = new Movie(this, "star_trails_resize.mov");
  backgoundMovie.play();
  
  // object set up
  location = new PVector(100,100);
  velocity = new PVector(1.5,2.1);
  gravity = new PVector(0,0.2);

  // foreground video set up
  myMovie = new Movie(this, "monkey.mov");
  myMovie.play();
}
  
void draw() {
  if (new_frame)
  {
    image(temp_image, 0, 0);
    new_frame = false;
    ball_movement();
  }
}

void velocity_degrade() {
   // Bounce off edges
  if ((location.x > width) || (location.x < 0)) {
    velocity.x = velocity.x * -0.85; // reduce the velocity ever so slightly
  }
  if (location.y > height) {
    // We're reducing velocity ever so slightly 
    // when it hits the bottom of the window
    velocity.y = velocity.y * -0.85; 
    location.y = height;
  } 
}

void ball_movement() {
   // Add velocity to the location.
  location.add(velocity);
  // Add gravity to velocity
  velocity.add(gravity);
  
  velocity_degrade();
  // Display circle at location vector
  stroke(255);
  if (!monkey_kick) fill(127,0,127);
  if (monkey_kick) fill(0,127,0);
  ellipse(location.x,location.y,48,48); 
}

void movieEvent(Movie m) {
  m.read();
  if (m == myMovie) {
    temp_image = m.get(0,0,m.width,m.height);
    temp_image = removeBackground(temp_image);
    new_frame = true;
    foreground_counter++;
  } else {
    background_movie[background_counter] = m.get(0,0,m.width,m.height);
    background_counter++;
  }
}

// resets the counter if we're passed the frame length of our background video once
// otherwise if we're passed it and we've reset it we'll increment the counter
void check_wrapped(int wrapped_background_counter) {
  if ((wrapped_background_counter == background_frames - 1) && !wrapped) {
    wrapped = true;
    background_counter = 0;
  }
  if (wrapped) {
   background_counter++; 
  }
}

PImage removeBackground(PImage frame) {
  int wrapped_background_counter = (background_counter - 1);
  check_wrapped(wrapped_background_counter);
  
  // marker iterator
  int marker_iterator = 0;
  
  // flag to see if monkey hit it on current frame
  monkey_kick = false;
  
  for (int x = 0; x < frame.width; x ++) {
    for (int y = 0; y < frame.height; y ++) {
      int loc = x + y * frame.width;
      color c = frame.pixels[loc];
      color bc = background_movie[wrapped_background_counter].pixels[loc];
      // identify blue background
      if ( ((red(c) < RED) && (green(c) < GREEN)) && blue(c) > BLUE_min && blue(c) < BLUE_max){
                frame.pixels[loc] = bc; 
      } else { // not the background
      // get the red segment markers
      if (red(c) > MONKEY_RED && green(c) < MONKEY_GREEN && blue(c) < MONKEY_BLUE) {
        //red_markers[foreground_counter][
          // if closer to the top then it is an arm
          //if (y < frame.height/2) {
          //  frame.pixels[loc] = -1;           
          //}
        }
        // if the ball hits the monkey anywhere within a range of the monkey's coords
        if (((location.x > x - 5 && location.x < x + 5) && (location.y > y -5 && location.y < y + 5)) && !monkey_kick) {
          if (velocity.x < 35 && velocity.x > -35) {
            monkey_kick = true;
            velocity.x = velocity.x * -1.5;
            velocity.y = velocity.y * -1.2;
          }
        }
      }
    }
  }
  println(velocity.x);
  println(velocity.y);
  frame.updatePixels();

  return frame;
}