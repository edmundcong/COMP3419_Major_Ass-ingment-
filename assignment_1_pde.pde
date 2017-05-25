import processing.video.*; //<>//
import processing.sound.*; // can we use this library?
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.ConcurrentModificationException;

Movie myMovie;
Movie backgoundMovie;

// sound file globals
SoundFile boing;
SoundFile hit;

//image globals
PImage lhs;
PImage rhs;
PImage banana_left;
PImage banana_right;
PImage armour;
PImage follower;


// Background removing colour threshholds
int BLUE_min = 60; // between 90 and 150
int BLUE_max = 255; // between 90 and 150
int GREEN_max = 200;
int GREEN_min = 0;
int RED_max = 180;
int RED_min = 0;
// monkey limb colour thresholds
// max red
int MONKEY_RED_MAX = 255; // monkey limb red value
int MONKEY_GREEN_MAX = 115;
int MONKEY_BLUE_MAX = 115;
// min red
int MONKEY_RED_MIN = 150; 
int MONKEY_GREEN_MIN = 30;
int MONKEY_BLUE_MIN = 30;

int DISTANCE_THRESHOLD = 25;

int BALL_SIZE = 48;
int CHASER_SIZE = 40;

// data structure for markers
ArrayList<Marker> markers = new ArrayList<Marker>();

// background
int background_frames = 532;
int background_counter = 0;
PImage[] background_movie = new PImage[background_frames];

// foreground
int foreground_frames = 955; 
int foreground_counter = 0;


// flags
boolean new_frame = false; // to render new frame without background
boolean wrapped = false;
boolean monkey_kick = false;
boolean access_array = false;

// temp variables
PImage temp_image;
PImage background_temp;

// variables to keep count
//int wrapped_background_counter = 0;
PVector location;  // Location of shape
PVector velocity;  // Velocity of shape
PVector gravity;   // Gravity acts at the shape's acceleration
PVector attraction;   // force which moves the ball towards the monkey
// to keep track if we're stuck at the edge of the screen
float x_ball_location = 0;

// keep track of average location of all blobs for tracking
float monkey_avg_x = 0;
float monkey_avg_y = 0;

int chasers = 1;
float chase_monkey_x = 0;
float chase_monkey_y = 0;
float chase_speed = 0.003;

int timer = 0;

void setup() {
  size(568, 320);
  // load sounds
  boing = new SoundFile(this, "boing.mp3");
  hit = new SoundFile(this, "hit.wav");
  
  // load images
  lhs = loadImage("lhs_sword.png");
  rhs = loadImage("rhs_sword.png");
  banana_left = loadImage("banana_left.png");
  banana_right = loadImage("banana_right.png");
  armour = loadImage("armour.png");
  follower = loadImage("follower.png");
  
  // background movie set up
  backgoundMovie = new Movie(this, "star_trails_resize.mov");
  backgoundMovie.play();
  backgoundMovie.volume(0);
  
  // object set up
  location = new PVector(100,100);
  velocity = new PVector(1.5,2.1);
  gravity = new PVector(0,0.2);

  // foreground video set up
  myMovie = new Movie(this, "monkey.mov");
  myMovie.play();
  myMovie.volume(0);
}
  
void draw() {
  if (new_frame)
  {
    image(temp_image, 0, 0);
    float temp_x = 1;
    float temp_y = 1;
    int valid_blobs_counter = 0;
    // safe way to iterate through a list while its being modified (by making a copy)
    for (Marker m : new ArrayList<Marker>(markers)) {
          if (m.size() > 250) {
            valid_blobs_counter++;
            m.show();
            temp_x += (m.minimum_x + m.maximum_x) / 2;
            temp_y += (m.minimum_y + m.maximum_y) / 2;
        }
    }
    //if (monkey_kick) image(hit_marker, (int) location.x * - 1.5, (int) location.y * - 1.2, 150, 150);
    follow_monkey(temp_x, temp_y, valid_blobs_counter);
    markers.clear(); // clear last marker blobs since we're just getting a snapshot
    new_frame = false;
    ball_movement();
  }
}


void follow_monkey(float temp_x, float temp_y, int valid_blobs_counter) {
  // get average coord of the monkey
  if (valid_blobs_counter > 0) {
     monkey_avg_x = temp_x / valid_blobs_counter;
     monkey_avg_y = temp_y / valid_blobs_counter;
     
     float x_diff = monkey_avg_x - chase_monkey_x;
     float y_diff = monkey_avg_y - chase_monkey_y;
     if (abs(x_diff) > 1) {
         chase_monkey_x += x_diff * chase_speed;
     }
     if (abs(y_diff) > 1) {
         chase_monkey_y += y_diff * chase_speed;
     }
    fill(150, 150, 200);
    image(follower, chase_monkey_x, chase_monkey_y, CHASER_SIZE, CHASER_SIZE);
    //ellipse(chase_monkey_x, chase_monkey_y, CHASER_SIZE, CHASER_SIZE);
  }
}

void velocity_degrade() {
   // Bounce off edges
  if ((location.x > width) || (location.x < 0)) {
    // to avoid getting stuck on boundarys since we dont want it to trigger the boundary of the next frame
    if (location.x > width) location.x = width;
    else if (location.x < 0) location.x = 0;
    velocity.x = velocity.x * -0.85; // reduce the velocity ever so slightly
    boing.play();
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
  ellipse(location.x,location.y,BALL_SIZE,BALL_SIZE);
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

void ball_detection(int x, int y) {
     // if the ball hits the monkey anywhere within a range of the monkey's coords
    if (((location.x > x - 5 && location.x < x + 5) && (location.y > y -5 && location.y < y + 5)) && !monkey_kick) {
        if (millis() - timer > 1000)
        {
          hit.play(); // only play every second to avoid lag when ball and monkey ticks too often
          timer = millis();
        }
      if (velocity.x < 35 && velocity.x > -35) { // make sure the ball doesn't go too fast
        monkey_kick = true;
        velocity.x = velocity.x * -1.5;
        velocity.y = velocity.y * -1.2;
        //image(hit_marker, x, y, 150, 150);
      }
    }
    // if the ball hits the chasing ball
    if ((location.x > chase_monkey_x - 25 && location.x < chase_monkey_x + 25) && 
        (location.y > chase_monkey_y - 25 && location.y < chase_monkey_y + 25)) {
        chase_monkey_x -= 25;
        chase_monkey_y -= 25;
        CHASER_SIZE = CHASER_SIZE + 15;
  }
  // if the chasing ball hits the monkey
   if ((x > chase_monkey_x - CHASER_SIZE && x < chase_monkey_x + CHASER_SIZE) && (y > chase_monkey_y - CHASER_SIZE && y < chase_monkey_y + CHASER_SIZE)) {
        chase_monkey_x -= 1.5;
        chase_monkey_y -= 1.2;
  }
}

PImage removeBackground(PImage frame) {
  int wrapped_background_counter = (background_counter - 1);
  check_wrapped(wrapped_background_counter);

  // flag to see if monkey hit it on current frame
  monkey_kick = false; //<>//
  for (int x = 0; x < frame.width; x ++) {
    for (int y = 0; y < frame.height; y ++) {
      int loc = x + y * frame.width;
      color c = frame.pixels[loc];
      color bc;
      if (background_movie.length > wrapped_background_counter && background_movie[wrapped_background_counter] != null) {
        bc = background_movie[wrapped_background_counter].pixels[loc];
      } else { 
        continue; 
     }
      // get the red segment markers
      float red = red(c);
      float green = green(c);
      float blue = blue(c);
      // identify blue background
      if ( ((red > RED_min && red < RED_max) && (green > GREEN_min && green < GREEN_max)) && (blue > BLUE_min && blue < BLUE_max)){
                frame.pixels[loc] = bc; 
      } else { // not the background
      if ((red > MONKEY_RED_MIN && red < MONKEY_RED_MAX) && (green > MONKEY_GREEN_MIN && green < MONKEY_GREEN_MAX) && (blue > MONKEY_BLUE_MIN && blue < MONKEY_BLUE_MAX)) {
          // anytime we've found a pixel we add a new marker object only if our arraylist of markers is empty
          boolean found = false;
          access_array = false; // mutex like flag
          // if its within the distance of another blob then just add to that blob and make it bigger
              try{
                for (Marker m : markers) {
                  if (m != null && m.is_near(x,y)) {
                     m.add(x, y);
                     found = true;
                     break;
                  } else { // not adding more to blob
                    
                  }
              }
              // catch concurrency and no such element errors
             } catch(NoSuchElementException e ) { continue;
             } catch(ConcurrentModificationException e) { continue; }
          
          // otherwise we'll make a new blob 
          if (!found && markers != null && markers.size() <= 5) { // <= 5 since 5 red markers
            Marker m = new Marker(x, y);
            markers.add(m);
          }
          access_array = true;
        }
        ball_detection(x, y);
      }
    }
  }
  frame.updatePixels();
  return frame;
}

float min_x = 568;
float max_x = 0;
float min_y = 320;
float max_y = 0;

// blob class for marker
class Marker {
 // keep track of top left and bottom right corners
 float minimum_x;
 float minimum_y;
 float maximum_x;
 float maximum_y;
 float centre_x;
 float centre_y;
 
 // 1 -> left arm, 2 -> right arm, 3 -> left leg, 4 -> right leg, 5 -> chest
 int m_part = 0;
 
 float m_width;
 float m_height;
 
 float m_screen_width = 568;
 float m_screen_height = 320;
 
 // constructor
 Marker(float x_arg, float y_arg) {
  minimum_x = x_arg;
  maximum_x = x_arg;
  minimum_y = y_arg;
  maximum_y = y_arg;
  centre_x = (minimum_x + maximum_x) / 2;
  centre_y = (minimum_y + maximum_y) / 2;
  closest_point();
 }
 
 // get locations of points closest to the corners
 void get_bounds() {
   if (centre_x < min_x) {
    min_x = centre_x; 
   }
   if (centre_x > max_x) {
    max_x = centre_x; 
   }
   if (centre_y < min_y) {
    min_y = centre_y; 
   }
   if (centre_y > max_y) {
    max_y = centre_y; 
   }
 }
 
 // find the closest point the monkey's blob is closest to
 void closest_point() {
   get_bounds();
   float diff_x = abs((m_screen_width - centre_x));
   float diff_y = abs((m_screen_height - centre_y));
   m_part = 0;
   //if (centre_x < max_x && centre_x > min_x && centre_y > min_y && centre_y < max_y) {
   //  //m_part = 5;
   //} else 
   if (centre_x < diff_x && centre_y < diff_y) { // top left quadrant
     m_part = 1;
   } else if (centre_x < diff_x && centre_y > diff_y) { // bottom left quadrant
     m_part = 3;
   } else if (centre_x > diff_x && centre_y < diff_y) { // top right quadrant
     m_part = 2;
   } else if (centre_x > diff_y && centre_y > diff_y) { // bottom right quadrant 
     m_part = 4;
   } 
 }
 
 float distance(float x_a, float y_a, float x_b, float y_b) {
   float distance = (x_b-x_a)*(x_b-x_a) + (y_b-y_a)*(y_b-y_a);
   return distance;
 }
 
  boolean is_near(float x_arg, float y_arg) {
    // finding the centre of the marker blob
    centre_x = (minimum_x + maximum_x) / 2;
    centre_y = (minimum_y + maximum_y) / 2;

    float distance = distance(centre_x, centre_y, x_arg, y_arg);
    if (distance < DISTANCE_THRESHOLD*DISTANCE_THRESHOLD) {
       return true; 
    } else {
      return false;
    }
  }
  
  void show() {
    if (m_part == 1) {
       image(lhs, minimum_x, minimum_y, 80, 80);
    } else if (m_part == 2) {
       image(rhs, minimum_x, minimum_y, 80, 80);
    } else if (m_part == 3) {
       image(banana_left, minimum_x, minimum_y, 80, 80);
    } else if (m_part == 4) {
       image(banana_right, minimum_x, minimum_y, 80, 80);
    } else {
       image(armour, minimum_x, minimum_y, 80, 80);
    }
        //stroke(0);
        //fill(255);
        //strokeWeight(2);
        //rectMode(CORNERS); // allows you to specify corners
        //rect(minimum_x, minimum_y, maximum_x, maximum_y); 
        //textSize(20); 
        //text(Integer.toString(m_part), minimum_x, minimum_y);  // Text wraps within text box   
    //}
  }
  
  float size() {
   return (maximum_x - minimum_x) * (maximum_y - minimum_y); 
  }
  
  void add(float x_arg, float y_arg) {
    minimum_x = min(minimum_x, x_arg);
    minimum_y = min(minimum_y, y_arg);
    maximum_x = max(maximum_x, x_arg);
    maximum_y = max(maximum_y, y_arg);
    closest_point();
  }
  
}