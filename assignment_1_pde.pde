import processing.video.*; //<>// //<>// //<>// //<>// //<>// //<>//
Movie myMovie;
Movie backgoundMovie;

// Background removing colour threshholds
int BLUE_min = 60; // between 90 and 150
int BLUE_max = 190; // between 90 and 150
int GREEN = 160;
int RED = 160;

// movie data structures

// background
int background_frames = 532;
int background_counter = 0;
PImage[] background_movie = new PImage[background_frames];

// foreground
int foreground_frames = 955; 
int foreground_counter = 0;

// flags
boolean new_frame = false; // to render new frame without background
boolean preprocessing = true;

// temp variables
PImage temp_image;
PImage background_temp;

// variables to keep count

void setup() {
  size(568, 320);
  backgoundMovie = new Movie(this, "star_trails_resize.mov");
  backgoundMovie.play();

  myMovie = new Movie(this, "monkey.mov");
  myMovie.play();
}
  
void draw() {
  if (new_frame)
  {
    image(temp_image, 0, 0);
    new_frame = false;
  }
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

PImage removeBackground(PImage frame) {
  int wrapped_background_counter = (background_counter - 1) % background_frames;
  for (int x = 0; x < frame.width; x ++)
    for (int y = 0; y < frame.height; y ++) {
      int loc = x + y * frame.width;
      color c = frame.pixels[loc];
      color bc = background_movie[wrapped_background_counter].pixels[loc];
      if ( ((red(c) < RED) && (green(c) < GREEN)) && blue(c) > BLUE_min && blue(c) < BLUE_max){
                frame.pixels[loc] = bc; 
      }
    }

  frame.updatePixels();

  return frame;
}