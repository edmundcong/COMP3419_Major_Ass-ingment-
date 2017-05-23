import processing.video.*; //<>//
import java.util.Iterator;
Movie myMovie;
Movie backgoundMovie;

// Background removing colour threshholds
int BLUE_min = 60; // between 90 and 150
int BLUE_max = 210; // between 90 and 150
int GREEN = 170;
int RED = 160;
// monkey limb colour thresholds
// max red
int MONKEY_RED_MAX = 255; // monkey limb red value
int MONKEY_GREEN_MAX = 160;
int MONKEY_BLUE_MAX = 160;
// min red
int MONKEY_RED_MIN = 150; 
int MONKEY_GREEN_MIN = 30;
int MONKEY_BLUE_MIN = 30;
int DISTANCE_THRESHOLD = 15;

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
    
    // make copy to avoid concurrent modification errors
    //(Element element : new ArrayList<Element>(mElements))
    //  for (int i=markers.size()-1; i>=0; i--) {
    //       Marker m = markers.get(i);
    //       if (m.size() > 600) m.show();
    //       markers.remove(m); 
    //  }

    //ArrayList<Marker> markers_temp = markers;
    ////marker iterator
    //Iterator<Marker> marker_iterator = markers_temp.iterator();
    for (Marker m : new ArrayList<Marker>(markers)) {
          if (m.size() > 600) m.show();
    }
    //while(marker_iterator.hasNext()) {
    //  Marker m = marker_iterator.next();
    //  if (m.size() > 600) m.show();
    //}
    //markers_temp.clear();
    markers.clear(); // clear last marker blobs since we're just getting a snapshot
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

void ball_detection(int x, int y) {
   // if the ball hits the monkey anywhere within a range of the monkey's coords
  if (((location.x > x - 5 && location.x < x + 5) && (location.y > y -5 && location.y < y + 5)) && !monkey_kick) {
    if (velocity.x < 35 && velocity.x > -35) {
      monkey_kick = true;
      velocity.x = velocity.x * -1.5;
      velocity.y = velocity.y * -1.2;
    }
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
      // identify blue background
      if ( ((red(c) < RED) && (green(c) < GREEN)) && blue(c) > BLUE_min && blue(c) < BLUE_max){
                frame.pixels[loc] = bc; 
      } else { // not the background
      // get the red segment markers
      float red = red(c);
      float green = green(c);
      float blue = blue(c);
      if ((red > MONKEY_RED_MIN && red < MONKEY_RED_MAX) && (green > MONKEY_GREEN_MIN && green < MONKEY_GREEN_MAX) && (blue > MONKEY_BLUE_MIN && blue < MONKEY_BLUE_MAX)) {
          // anytime we've found a pixel we add a new marker object only if our arraylist of markers is empty
          boolean found = false;
          access_array = false; // mutex like flag
          // if its within the distance of another blob then just add to that blob and make it bigger
          for (Marker m : markers) {
            if (m != null && m.is_near(x,y)) {
               m.add(x, y);
               found = true;
               break;
            }
          }
          //// otherwise we'll make a new blob
          if (!found && markers != null) {
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

// blob class for marker
class Marker {
 // keep track of top left and bottom right corners
 float minimum_x;
 float minimum_y;
 float maximum_x;
 float maximum_y;
 
 float m_width;
 float m_height;
 
 // constructor
 Marker(float x_arg, float y_arg) {
  minimum_x = x_arg;
  maximum_x = x_arg;
  minimum_y = y_arg;
  maximum_y = y_arg;
 }
 
 float distance(float x_a, float y_a, float x_b, float y_b) {
   float distance = (x_b-x_a)*(x_b-x_a) + (y_b-y_a)*(y_b-y_a);
   return distance;
 }
 
  boolean is_near(float x_arg, float y_arg) {
    // finding the centre of the marker blob
    float centre_x = (minimum_x + maximum_x) / 2;
    float centre_y = (minimum_y + maximum_y) / 2;

    float distance = distance(centre_x, centre_y, x_arg, y_arg);
    if (distance < DISTANCE_THRESHOLD*DISTANCE_THRESHOLD) {
       return true; 
    } else {
      return false;
    }
  }
  
  void show() {
    stroke(0);
    fill(255);
    strokeWeight(2);
    rectMode(CORNERS); // allows you to specify corners
    rect(minimum_x, minimum_y, maximum_x, maximum_y);
  }
  
  float size() {
   return (maximum_x - minimum_x) * (maximum_y - minimum_y); 
  }
  
  void add(float x_arg, float y_arg) {
    minimum_x = min(minimum_x, x_arg);
    minimum_y = min(minimum_y, y_arg);
    maximum_x = max(maximum_x, x_arg);
    maximum_y = max(maximum_y, y_arg);
  }
  
}