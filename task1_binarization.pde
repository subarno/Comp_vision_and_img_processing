void setup() {
  size(1200, 800);
  PImage img = loadImage("robotmarko.jpg");
  
  PImage grayImg = convertToGrayscale(img);

  PImage globalBinarized = globalAdaptiveThresholding(img, 0.5);
  PImage localBinarized = localAdaptiveThresholding(img, 51, 51); // higher value of h & w

  image(img, 0,0);
  image(grayImg, 600, 0);
  image(globalBinarized, 0, 400);
  image(localBinarized, 600, 400);
}

PImage convertToGrayscale(PImage img) {
  PImage gray = createImage(img.width, img.height, RGB);
  img.loadPixels();
  gray.loadPixels();
  
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      int index = x + y * img.width;
      float r = brightness(img.pixels[index]);
      gray.pixels[index] = color(r);
    }
  }
  
  gray.updatePixels();
  return gray;
}

PImage globalAdaptiveThresholding(PImage img, float epsilon) {
  img.loadPixels();
  
  float initialThreshold = 127; //not to be hardcoded
  float currentThreshold = initialThreshold;
  float previousThreshold;
  
  do {
    previousThreshold = currentThreshold;
    float sum1 = 0, sum2 = 0;
    int count1 = 0, count2 = 0;

    for (int i = 0; i < img.pixels.length; i++) {
      float pixelBrightness = brightness(img.pixels[i]);
      if (pixelBrightness >= previousThreshold) {
        sum1 += pixelBrightness;
        count1++;
      } else {
        sum2 += pixelBrightness;
        count2++;
      }
    }
    
    float mean1 = (count1 > 0) ? sum1 / count1 : 0;
    float mean2 = (count2 > 0) ? sum2 / count2 : 0;
    currentThreshold = (mean1 + mean2) / 2;
  } while (abs(currentThreshold - previousThreshold) > epsilon);
  
  PImage binarizedImg = createImage(img.width, img.height, RGB);
  binarizedImg.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) {
    binarizedImg.pixels[i] = (brightness(img.pixels[i]) >= currentThreshold) ? color(255) : color(0);
  }
  binarizedImg.updatePixels();
  return binarizedImg;
}

PImage localAdaptiveThresholding(PImage img, int Ww, int Hw) {
  PImage binarizedImg = createImage(img.width, img.height, RGB);
  img.loadPixels();
  binarizedImg.loadPixels();

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      float sum = 0;
      int count = 0;
      for (int ky = -Hw / 2; ky <= Hw / 2; ky++) {
        for (int kx = -Ww / 2; kx <= Ww / 2; kx++) {
          int nx = constrain(x + kx, 0, img.width - 1);
          int ny = constrain(y + ky, 0, img.height - 1);
          sum += brightness(img.pixels[ny * img.width + nx]);
          count++;
        }
      }
      float localThreshold = sum / count;
      float pixelBrightness = brightness(img.pixels[y * img.width + x]);
      binarizedImg.pixels[y * img.width + x] = (pixelBrightness >= localThreshold) ? color(255) : color(0);
    }
  }
  binarizedImg.updatePixels();
  return binarizedImg;
}
