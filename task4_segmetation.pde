PImage orig, gray;
int[] parent, compSize;
int w, h;

void setup() {
  size(800, 400);
  orig = loadImage("car-registration-plate-guide-1.jpg");
  
  gray = createImage(orig.width, orig.height, RGB);
  orig.loadPixels();
  gray.loadPixels();
  for (int i = 0; i < orig.pixels.length; i++) {
    float b = brightness(orig.pixels[i]);
    gray.pixels[i] = color(b);
  }
  gray.updatePixels();
  
  float thresh = 5;               
  segmentGraph(gray, thresh);      
  
  int N = w * h;
  int[] rootLabel = new int[N];
  for (int i = 0; i < N; i++) {
    rootLabel[i] = -1;
  }
  int[] compactLabels = new int[N];
  int numSegments = 0;
  for (int i = 0; i < N; i++) {
    int r = find(i);
    if (rootLabel[r] == -1) {
      rootLabel[r] = numSegments++;
    }
    compactLabels[i] = rootLabel[r];
  }
  
  println("Number of segments: " + numSegments);
  
  randomSeed(millis());
  
  colorMode(HSB, 255);
  int[] segmentColors = new int[numSegments];
  for (int i = 0; i < numSegments; i++) {
    float hue = random(0, 255);
    segmentColors[i] = color(hue, 200, 200);
  }
  
  PImage seg = createImage(w, h, RGB);
  seg.loadPixels();
  for (int i = 0; i < N; i++) {
    seg.pixels[i] = segmentColors[compactLabels[i]];
  }
  seg.updatePixels();
  
  image(gray, 0, 0);
  image(seg, 0, h + 10);
}

void segmentGraph(PImage img, float thr) {
  w = img.width;
  h = img.height;
  int N = w * h;
  
  parent   = new int[N];
  compSize = new int[N];
  for (int i = 0; i < N; i++) {
    parent[i] = i;
    compSize[i] = 1;
  }
  
  ArrayList<Edge> edges = new ArrayList<Edge>();
  img.loadPixels();
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int i = y * w + x;
      if (x < w - 1) {
        int j = i + 1;
        float d = abs(brightness(img.pixels[i]) - brightness(img.pixels[j]));
        edges.add(new Edge(i, j, d));
      }
      if (y < h - 1) {
        int j = i + w;
        float d = abs(brightness(img.pixels[i]) - brightness(img.pixels[j]));
        edges.add(new Edge(i, j, d));
      }
      if (x < w - 1 && y < h - 1) {
        int j = i + w + 1;
        float d = abs(brightness(img.pixels[i]) - brightness(img.pixels[j]));
        edges.add(new Edge(i, j, d));
      }
    }
  }
  
  edges.sort((a, b) -> Float.compare(a.w, b.w));
  for (Edge e : edges) {
    if (e.w <= thr) {
      merge(e.u, e.v);
    }
  }
}

int find(int x) {
  if (parent[x] != x) {
    parent[x] = find(parent[x]);
  }
  return parent[x];
}

void merge(int a, int b) {
  int ra = find(a), rb = find(b);
  if (ra == rb) return;
  if (compSize[ra] < compSize[rb]) {
    parent[ra] = rb;
    compSize[rb] += compSize[ra];
  } else {
    parent[rb] = ra;
    compSize[ra] += compSize[rb];
  }
}

class Edge {
  int u, v;
  float w;
  Edge(int u, int v, float w) {
    this.u = u;
    this.v = v;
    this.w = w;
  }
}
