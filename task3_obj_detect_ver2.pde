PImage img1, img2;
ArrayList<Detection> finalDetections = new ArrayList<Detection>();
final int[][] DIRECTIONS = {{-1,0},{-1,1},{0,1},{1,1},{1,0},{1,-1},{0,-1},{-1,-1}};

boolean SHOW_DEBUG = true;
float SIMILARITY_THRESHOLD = 0.98;
int STEP_SIZE = 5;
int GRID_X = 2;
int GRID_Y = 2;

class Detection {
  int x, y, w, h;
  float score;
  Detection(int x, int y, int w, int h, float score) {
    this.x = x; this.y = y; 
    this.w = w; this.h = h; 
    this.score = score;
  }
}

void setup() {
  size(1200, 800);
  surface.setTitle("Object Detector - Corrected Version");
  
  try {
    img1 = loadImage("img-2.jpg");
    img2 = loadImage("car-registration-plate-guide-1.jpg");
    
    if(img1 == null || img2 == null) {
      throw new RuntimeException("Failed to load images");
    }
    
    PImage template = preprocessImage(img1, true);
    PImage scene = preprocessImage(img2, true);
    
    objectDetection(template, scene);
    displayResults();
    
  } catch(Exception e) {
    println("Error: " + e.getMessage());
    exit();
  }
}

PImage preprocessImage(PImage img, boolean invert) {
  img = img.copy();
  img.filter(GRAY);
  img = adaptiveBinarize(img, 25, 2.0);
  if(invert) img.filter(INVERT);
  return img;
}

PImage adaptiveBinarize(PImage img, int blockSize, float C) {
  img.loadPixels();
  PImage result = createImage(img.width, img.height, RGB);
  
  for(int y = 0; y < img.height; y++) {
    for(int x = 0; x < img.width; x++) {
      float sum = 0;
      int count = 0;
      
      for(int dy = -blockSize/2; dy <= blockSize/2; dy++) {
        for(int dx = -blockSize/2; dx <= blockSize/2; dx++) {
          int nx = constrain(x+dx, 0, img.width-1);
          int ny = constrain(y+dy, 0, img.height-1);
          sum += brightness(img.pixels[ny*img.width + nx]);
          count++;
        }
      }
      float threshold = sum/count - C;
      result.pixels[y*img.width + x] = 
        brightness(img.pixels[y*img.width + x]) > threshold ? 
        color(255) : color(0);
    }
  }
  result.updatePixels();
  return result;
}

void objectDetection(PImage template, PImage scene) {
  int winW = template.width;
  int winH = template.height;
  
  if(winW <= 0 || winH <= 0) {
    throw new RuntimeException("Invalid template dimensions");
  }
  
  float[] templateFeatures = calculateFeatures(template);
  ArrayList<Detection> rawDetections = new ArrayList<Detection>();
  
  for(int y = 0; y <= scene.height - winH; y += STEP_SIZE) {
    for(int x = 0; x <= scene.width - winW; x += STEP_SIZE) {
      PImage window = scene.get(x, y, winW, winH);
      float[] windowFeatures = calculateFeatures(window);
      float similarity = cosineSimilarity(templateFeatures, windowFeatures);
      
      if(similarity >= SIMILARITY_THRESHOLD) {
        rawDetections.add(new Detection(x, y, winW, winH, similarity));
      }
    }
  }
  
  finalDetections = nonMaxSuppression(rawDetections, 0.5);
}

float[] calculateFeatures(PImage img) {
  int cellW = img.width/GRID_X;
  int cellH = img.height/GRID_Y;
  float[][][] hist = new float[GRID_Y][GRID_X][DIRECTIONS.length];
  
  img.loadPixels();
  for(int y = 1; y < img.height-1; y++) {
    for(int x = 1; x < img.width-1; x++) {
      if(brightness(img.pixels[y*img.width + x]) == 255) {
        int cy = constrain(y/cellH, 0, GRID_Y-1);
        int cx = constrain(x/cellW, 0, GRID_X-1);
        
        for(int d = 0; d < DIRECTIONS.length; d++) {
          int nx = x + DIRECTIONS[d][0];
          int ny = y + DIRECTIONS[d][1];
          if(nx >= 0 && ny >= 0 && nx < img.width && ny < img.height) {
            if(brightness(img.pixels[ny*img.width + nx]) == 0) {
              hist[cy][cx][d]++;
            }
          }
        }
      }
    }
  }
  
  float[] features = new float[GRID_X * GRID_Y * DIRECTIONS.length];
  int idx = 0;
  for(int cy = 0; cy < GRID_Y; cy++) {
    for(int cx = 0; cx < GRID_X; cx++) {
      float sum = 0;
      for(float v : hist[cy][cx]) sum += v;
      for(int d = 0; d < DIRECTIONS.length; d++) {
        features[idx++] = sum > 0 ? hist[cy][cx][d]/sum : 0;
      }
    }
  }
  return features;
}

ArrayList<Detection> nonMaxSuppression(ArrayList<Detection> detections, float iouThreshold) {
  detections.sort((a, b) -> Float.compare(b.score, a.score));
  ArrayList<Detection> results = new ArrayList<Detection>();
  
  while(!detections.isEmpty()) {
    Detection best = detections.remove(0);
    results.add(best);
    
    for(int i = detections.size()-1; i >= 0; i--) {
      if(calculateIoU(best, detections.get(i)) > iouThreshold) {
        detections.remove(i);
      }
    }
  }
  return results;
}

float calculateIoU(Detection a, Detection b) {
  int x1 = max(a.x, b.x);
  int y1 = max(a.y, b.y);
  int x2 = min(a.x + a.w, b.x + b.w);
  int y2 = min(a.y + a.h, b.y + b.h);
  
  float intersection = max(0, x2 - x1) * max(0, y2 - y1);
  float union = a.w*a.h + b.w*b.h - intersection;
  return union > 0 ? intersection/union : 0;
}

float cosineSimilarity(float[] a, float[] b) {
  float dot = 0, magA = 0, magB = 0;
  for(int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  return magA == 0 || magB == 0 ? 0 : dot/(sqrt(magA)*sqrt(magB));
}

void displayResults() {
  background(255);
  image(img1, 10, 10);
  image(img2, img1.width + 20, 10);
  
  stroke(255, 0, 0);
  noFill();
  for(Detection d : finalDetections) {
    rect(img1.width + 20 + d.x, 10 + d.y, d.w, d.h);
  }
  
  fill(0);
  textSize(14);
  text("Detections: " + finalDetections.size(), 20, height-20);
}
