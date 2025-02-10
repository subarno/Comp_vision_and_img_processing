PImage image1, image2;

void setup() {
  size(1200, 800);
  image1 = preprocess("artem-stoliar-Usy12zpjZ5Y-unsplash.jpg");
  image2 = preprocess("simon-spring-daClflufF3M-unsplash.jpg");

  int orientations = 9;  
  int cellSize = 8;     
  int blockSize = 2;    

  float[] hog1 = computeHOG(image1, orientations, cellSize, blockSize);
  float[] hog2 = computeHOG(image2, orientations, cellSize, blockSize);

  float similarity = cosineSimilarity(hog1, hog2);
  println("Cosine similarity: " + similarity);

  displayResult(image1, image2, similarity);
}

PImage preprocess(String fileName) {
  PImage img = loadImage(fileName);
  img.filter(GRAY);
  img.resize(400, 400);
  return img;
}

float[] computeHOG(PImage img, int orientations, int cellSize, int blockSize) {
  img.loadPixels();
  int width = img.width, height = img.height;
  int cellsX = width / cellSize, cellsY = height / cellSize;
  float[] histogram = new float[cellsX * cellsY * orientations];

  int[] sobelX = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
  int[] sobelY = {-1, -2, -1, 0, 0, 0, 1, 2, 1};

  float[] magnitude = new float[width * height];
  float[] orientation = new float[width * height];

  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      int index = x + y * width;

      float gx = 0, gy = 0;
      int kernelIndex = 0;

      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++, kernelIndex++) {
          int pixelIndex = (x + j) + (y + i) * width;
          float brightnessVal = brightness(img.pixels[pixelIndex]);
          gx += sobelX[kernelIndex] * brightnessVal;
          gy += sobelY[kernelIndex] * brightnessVal;
        }
      }

      float[] grad = gradient_vector2(gx,gy);
      float mag = grad[0];
      float theta = grad[1];
      println("magnitude = " + mag + ", orientation = " + theta);

      magnitude[index] = mag;
      orientation[index] = theta;
    }
  }

  for (int y = 0; y < cellsY; y++) {
    for (int x = 0; x < cellsX; x++) {
      for (int dy = 0; dy < cellSize; dy++) {
        for (int dx = 0; dx < cellSize; dx++) {
          int px = x * cellSize + dx;
          int py = y * cellSize + dy;
          int index = px + py * width;
          
          float mag = magnitude[index];
          float theta = orientation[index];
          int bin = int(theta * orientations / TWO_PI);

          histogram[(y * cellsX + x) * orientations + bin] += mag;
        }
      }
    }
  }

  return normalizeHistogram(histogram, cellsX, cellsY, orientations, blockSize);
}

float[] gradient_vector2(float gx, float gy) {
  float mag = sqrt(gx * gx + gy * gy);
  float theta = atan2(gy, gx);
  if (theta < 0)
    theta += TWO_PI;
  return new float[]{mag, theta};
}

float[] normalizeHistogram(float[] histogram, int cellsX, int cellsY, int orientations, int blockSize) {
  int blocksX = cellsX - blockSize + 1;
  int blocksY = cellsY - blockSize + 1;
  float[] normalizedHOG = new float[blocksX * blocksY * orientations * blockSize * blockSize];

  int index = 0;
  for (int by = 0; by < blocksY; by++) {
    for (int bx = 0; bx < blocksX; bx++) {
      float sumSq = 0;

      // Compute L2 norm over the block
      for (int dy = 0; dy < blockSize; dy++) {
        for (int dx = 0; dx < blockSize; dx++) {
          for (int o = 0; o < orientations; o++) {
            float value = histogram[((by + dy) * cellsX + (bx + dx)) * orientations + o];
            sumSq += value * value;
          }
        }
      }

      float normFactor = 1.0 / (sqrt(sumSq) + 1e-6);

      for (int dy = 0; dy < blockSize; dy++) {
        for (int dx = 0; dx < blockSize; dx++) {
          for (int o = 0; o < orientations; o++) {
            float value = histogram[((by + dy) * cellsX + (bx + dx)) * orientations + o];
            normalizedHOG[index++] = value * normFactor;
          }
        }
      }
    }
  }

  return normalizedHOG;
}

float cosineSimilarity(float[] vec1, float[] vec2) {
  float dotProduct = 0, mag1 = 0, mag2 = 0;
  
  for (int i = 0; i < vec1.length; i++) {
    dotProduct += vec1[i] * vec2[i];
    mag1 += vec1[i] * vec1[i];
    mag2 += vec2[i] * vec2[i];
  }

  return (mag1 == 0 || mag2 == 0) ? 0 : dotProduct / (sqrt(mag1) * sqrt(mag2));
}

void displayResult(PImage img1, PImage img2, float similarity) {
  image(img1, 60, 40);
  image(img2, img1.width + 80, 40);
  
  fill(0);
  textSize(25);
  textAlign(RIGHT);
  text("Cosine Similarity: " + nf(similarity, 0, 5), width / 2, img1.height + 100);
}
