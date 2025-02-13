PImage img1, img2;

void setup() {
  size(1200, 800);
  img1 = loadImage("img-A.jpg");
  img2 = loadImage("car-registration-plate-guide-1.jpg");
  
  display(img1, img2);
  
  img1 = preProcess(img1);
  img2 = preProcess(img2);
  
  //display(img1, img2);
  
  object_detection(img1, img2,
                   8, 2, 2,                     // directions, gridX, gridY
                   img1.width, img1.height,     // window size
                   3, 3,                        // window step size
                   0.99,                        // threshold
                   img1.width + 10, 0);
}

PImage preProcess(PImage img) {
  img.filter(GRAY);
  img = binarize(img, 51);
  return img;
}

PImage binarize(PImage img, int blockSize) {
  img.loadPixels();
  PImage binarizedImg = createImage(img.width, img.height, RGB);

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      float sum = 0;
      int count = 0;
      
      for (int dy = -blockSize/2; dy <= blockSize/2; dy++) {
        for (int dx = -blockSize/2; dx <= blockSize/2; dx++) {
          int nx = constrain(x+dx, 0, img.width-1);
          int ny = constrain(y+dy, 0, img.height-1);
          sum += brightness(img.pixels[ny*img.width + nx]);
          count++;
        }
      }
      float thresh = sum / count;
      float pixelBrightness = brightness(img.pixels[y*img.width + x]);
      binarizedImg.pixels[y*img.width + x] = pixelBrightness > thresh ? color(255) : color(0);
    }
  }
  binarizedImg.updatePixels();
  return binarizedImg;
}

void object_detection(PImage temp, PImage image,
                     int n, int M, int N,
                     int winW, int winH,
                     int stepX, int stepY,
                     float threshold,
                     int xpos, int ypos) {
  
  temp.resize(winW, winH);
  float[] tempHOG = computeHOG(temp, n, M, N);
  
  println("Starting similarity comparisons:");
  int comparisonCount = 0;
  float maxSimilarity = 0;
  
  for(int y = 0; y <= image.height - winH; y += stepY) {
    for(int x = 0; x <= image.width - winW; x += stepX) {
      PImage window = image.get(x, y, winW, winH);
      float[] windowHOG = computeHOG(window, n, M, N);
      float similarity = cosineSimilarity(tempHOG, windowHOG);
      
      println("Comparison #" + (++comparisonCount) + " at (" + x + "," + y + "): " + similarity);
      
      if(similarity >= threshold) {
        float[] detected = new float[] {xpos + x, ypos + y, winW, winH, similarity};
        drawRect(detected);
      }
      if(similarity > maxSimilarity) 
        maxSimilarity = similarity;
    }
  }
  
  println("\nTotal comparisons: " + comparisonCount);
  println("Maximum similarity found: " + maxSimilarity);
}

float[] computeHOG(PImage img, int n, int M, int N) {
  int[][] sobelX = {{-1,0,1}, {-2,0,2}, {-1,0,1}};
  int[][] sobelY = {{-1,-2,-1}, {0,0,0}, {1,2,1}};
  int cellW = img.width / M;
  int cellH = img.height / N;
  float[] histogram = new float[M * N * n];
  
  img.loadPixels();
  for (int y = 1; y < img.height - 1; y++) {
    for (int x = 1; x < img.width - 1; x++) {
      float dx = 0, dy = 0;
      
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          int pixel = brightness(img.pixels[(y + i) * img.width + (x + j)]) == 0 ? 1 : 0;
          dx += pixel * sobelX[i + 1][j + 1];
          dy += pixel * sobelY[i + 1][j + 1];
        }
      }
      
      float magnitude = sqrt(dx * dx + dy * dy);
      float angle = atan2(dy, dx);
      if (angle < 0) angle += TWO_PI;
      int bin = int((angle / TWO_PI) * n) % n;
      
      int cy = constrain(y / cellH, 0, N - 1);
      int cx = constrain(x / cellW, 0, M - 1);
      
      histogram[cy * M * n + cx * n + bin] += magnitude;
    }
  }
  return normalizeHOGPerCell(histogram, n, M, N);
}

float[] normalizeHOGPerCell(float[] histogram, int n, int M, int N) {
  for (int i = 0; i < M * N; i++) {
    float sum = 0;
    for (int j = 0; j < n; j++) {
      sum += histogram[i * n + j] * histogram[i * n + j];
    }
    float normFactor = (sum > 0) ? 1.0 / sqrt(sum) : 0;
    for (int j = 0; j < n; j++) {
      histogram[i * n + j] *= normFactor;
    }
  }
  return histogram;
}

float cosineSimilarity(float[] a, float[] b) {
  float dot = 0, magA = 0, magB = 0;
  for(int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  return magA == 0 || magB == 0 ? 0 : dot / (sqrt(magA) * sqrt(magB));
}

void display(PImage img1, PImage img2) {
  int a=0 , b=0;
  image(img1, a, b);
  image(img2, img1.width + 10, 0);
}

void drawRect(float[] d) {
  stroke(255, 0, 0);
  noFill();
  rect(d[0], d[1], d[2], d[3]);
}
