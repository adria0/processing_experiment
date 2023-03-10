/**
 * ASCII Video
 * by Ben Fry.
 *
 *
 * Text characters have been used to represent images since the earliest computers.
 * This sketch is a simple homage that re-interprets live video as ASCII text.
 * See the keyPressed() function for more options, like changing the font size.
 */

import processing.video.*;
import processing.sound.*;

AudioIn input;
Amplitude analyzer;
SoundFile twinklesparkle;
SoundFile magicharp;
SoundFile misteryunfold;
Capture video;
boolean cheatScreen;

// Characters sorted according to their visual density
String letterOrder =
  " .`-_':,;^=+/\"|)\\<>)iv%xclrs{*}I?!][1taeo7zjLu" +
  "nT#JCwfy325Fp6mqSghVd4EgXPGZbYkOA&8U$@KHDBWNMR0Q";
char[] letters;

float[] bright;

PFont font;
float fontSize = 1.5;
boolean capture;
int rand =0 ;

void setup() {
  size(640, 480);

  // This the default video input, see the GettingStartedCapture
  // example if it creates an error
  video = new Capture(this, 160, 120, "pipeline:avfvideosrc device-index=0 ! video/x-raw, width=640, height=480, framerate=30/1");

  // Start capturing the images from the camera
  video.start();

  int count = video.width * video.height;
  //println(count);

  font = loadFont("UniversLTStd-Light-48.vlw");

  // for the 256 levels of brightness, distribute the letters across
  // the an array of 256 elements to use for the lookup
  letters = new char[256];
  for (int i = 0; i < 256; i++) {
    int index = int(map(i, 0, 256, 0, letterOrder.length()));
    letters[i] = letterOrder.charAt(index);
  }

  // current brightness for each point
  bright = new float[count];
  for (int i = 0; i < count; i++) {
    // set each brightness at the midpoint to start
    bright[i] = 128;
  }
  
    // Start listening to the microphone
  // Create an Audio input and grab the 1st channel
  input = new AudioIn(this, 0);

  // start the Audio Input
  input.start();

  // create a new Amplitude analyzer
  analyzer = new Amplitude(this);

  // Patch the input to an volume analyzer
  analyzer.input(input);
  
  twinklesparkle = new SoundFile(this, "./sound-effect-twinklesparkle-115095.mp3");
  magicharp = new SoundFile(this,"./magic-harp-logo-103888.mp3");
  misteryunfold = new SoundFile(this, "./let-the-mystery-unfold-122118.mp3");
}  


void captureEvent(Capture c) {
  c.read();
}

int add_rand_max(int v) {
  int vv = v + (int)random(frameCount % 50) + (int)random(frameCount % 10000) / 10;
  if (vv > 255) {
    return 255;
  } else {
    return vv;
  }

}

boolean draw_normal(boolean start) {
  boolean next_step = false;
  
  tint(60);
  PImage img;
  img = loadImage("./card_" + nf((frameCount / 10)% 22) + ".jpg");
  image(img, -1000,-1000,2000,2000);

  float vol = analyzer.analyze();

  pushMatrix();

  float hgap = width / float(video.width);
  float vgap = height / float(video.height);

  scale(max(hgap, vgap) * fontSize);
  textFont(font, fontSize);

  int index = 0;
  video.loadPixels();
  float accum = 0;
  for (int y = 1; y < video.height; y++) {

    // Move down for next line
    translate(0,  1.0 / fontSize);

    pushMatrix();
    for (int x = 0; x < video.width; x++) {
      int pixelColor = video.pixels[index];
      rand += pixelColor;
      if (rand <0 ) {
        rand = -rand;
      }
      
      // Faster method of calculating r, g, b than red(), green(), blue()
      int r = add_rand_max((pixelColor >> 16) & 0xff);
      int g = add_rand_max((pixelColor >> 8) & 0xff);
      int b = add_rand_max(pixelColor & 0xff);

      // Another option would be to properly calculate brightness as luminance:
      // luminance = 0.3*red + 0.59*green + 0.11*blue
      // Or you could instead red + green + blue, and make the the values[] array
      // 256*3 elements long instead of just 256.
      int pixelBright = max(r, g, b);

      // The 0.1 value is used to damp the changes so that letters flicker less
      float diff = pixelBright - bright[index];
      bright[index] += diff * 0.1;
      accum += bright[index];
      
      fill(pixelColor);
      int num = int(bright[index]);
        text(letters[num], 0, 0);
  
      if (vol > 0.1) {
        // Move to the next pixel
        index+=1+random(1);
        next_step = true;
        if (!twinklesparkle.isPlaying()) {
           twinklesparkle.play(); 
        }
      } else {
        index+=1;
      }
      
      // Move over for next character
      translate(1.0 / fontSize, 0);
    }
    popMatrix();
  }
  popMatrix();


  if (cheatScreen) {
    //image(video, 0, height - video.height);
    // set() is faster than image() when drawing untransformed images
    set(0, height - video.height, video);
  }
  return next_step;
}

int draw_card_counter = 0;
int cards[] = new int[0];

boolean in_array(int v, int[] array) {
  for (int i=0;i<array.length;i++) {
     if (array[i] == v) {
        return true;
     }
  }
  return false;
}

boolean draw_card(boolean start) {
  if (start) {
     if (cards.length == 3 ) {
       cards = new int[0];
       return true;
     } else if (cards.length < 2 ) {
        draw_card_counter = 100;
     } else {
        magicharp.play();
        misteryunfold.stop();
        draw_card_counter = 200;
     }
     int card = rand % 22;
     while (in_array(card, cards)) {
       card = rand % 22;
     }
     cards = append(cards,card);
  } else {
     draw_card_counter -=1;
  }
  
  if (draw_card_counter > 0) {
    tint(255);
    for (int i=0;i<cards.length;i++) {
       PImage img;
       img = loadImage(("./card_" + nf(cards[i]) + ".jpg"));
       int w = 200; 
       int h = (int)(((float)img.height / (float)img.width) * (float)w);
       image(img,( width - w * 3)/2  +  i * w , (height - h) / 2, w, h);
    }
    return false;
  } else {
    return true;
  }                             
}

int draw_step = 0;
boolean draw_start = true;
void draw() {
  switch (draw_step) {
    case 0: draw_start=draw_normal(draw_start); break;
    case 1: draw_start=draw_card(draw_start); break;
  }
  if (draw_start) {
    draw_step = (draw_step + 1) % 2;
  }
}

/**
 * Handle key presses:
 * 'c' toggles the cheat screen that shows the original image in the corner
 * 'g' grabs an image and saves the frame to a tiff image
 * 'f' and 'F' increase and decrease the font size
 */
void keyPressed() {
  if (key == 32 && !misteryunfold.isPlaying()) {
    misteryunfold.play();
  }
}
        
