PImage image1, image2;

void setup() {
  size(1200, 800);
  image1 = preprocess("artem-stoliar-Usy12zpjZ5Y-unsplash.jpg");
  image2 = preprocess("artem-stoliar-Usy12zpjZ5Y-unsplash.jpg");
  int orientations = 20;
  int cellSize = 20;
  float[] hog1 = computeHOG(image1, orientations, cellSize);
  float[] hog2 = computeHOG(image2, orientations, cellSize);
  float similarity = cosineSimilarity(hog1, hog2);
  println("Cosine similarity between the two HOG feature vectors: " + similarity);
  displayResult(image1, image2, similarity);
}

PImage preprocess(String fileName) {
  PImage img = loadImage(fileName);
  img.filter(GRAY);
  img.resize(400, 400);
  return img;
}

float[] computeHOG(PImage img, int orientations, int cellSize) {
  img.loadPixels();
  
  int cellsX = img.width / cellSize;
  int cellsY = img.height / cellSize;
  float[] histogram = new float[cellsX * cellsY * orientations];

  for (int y = 1; y < img.height - 1; y++) {
    for (int x = 1; x < img.width - 1; x++) {
      int index = x + y * img.width;

      float gx = brightness(img.pixels[index + 1]) - brightness(img.pixels[index - 1]);
      float gy = brightness(img.pixels[index + img.width]) - brightness(img.pixels[index - img.width]);
      
      float[] gradient = gradient_vector2(gx,gy);

      float magnitude = gradient[0];
      float orientation = gradient[1];

      float[] bin = decompose2(magnitude, orientation, orientations);

      int cellX = x / cellSize;
      int cellY = y / cellSize;

      for (int i = 0; i < orientations; i++) {
        histogram[(cellY * cellsX + cellX) * orientations + i] += bin[i];
      }
    }
  }

  return histogram;
}

float[] gradient_vector2(float gx, float gy) {
  float mag = sqrt(gx * gx + gy * gy);
  float theta = atan2(gy, gx);
  if (theta < 0)
    theta += TWO_PI;
  println("magnitude = " + mag + ", orientation = " + theta);
  return new float[]{mag, theta};
}

float[] decompose2(float gx, float gy, int n) {
  float mag = sqrt(gx * gx + gy * gy);
  float theta = atan2(gy, gx);
  if (theta < 0)
    theta += TWO_PI;
  float[] d = new float[n];
  int i = int(theta * n / TWO_PI);
  d[i] = mag;
  return d;
}

float cosineSimilarity(float[] vec1, float[] vec2) {
  PVector v1 = new PVector(0, 0, 0);

  for (int i = 0; i < vec1.length; i++) {
    v1.x += vec1[i] * vec2[i];
    v1.y += vec1[i] * vec1[i];
    v1.z += vec2[i] * vec2[i];
  }

  return (v1.y == 0 || v1.z == 0) ? 0 : v1.x / (sqrt(v1.y) * sqrt(v1.z));
}

void displayResult(PImage img1, PImage img2, float similarity) {
  image(img1, 60, 40);
  image(img2, img1.width + 80, 40);
  
  fill(0);
  textSize(25);
  textAlign(RIGHT);
  text("Cosine Similarity: " + nf(similarity, 0, 5), width / 2, img1.height + 100);
}
