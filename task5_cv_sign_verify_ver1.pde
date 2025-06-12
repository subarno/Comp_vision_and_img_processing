String fileA = "U1S1.TXT";
String fileB = "U1S5.TXT";

ArrayList<String> seqA, seqB;

void setup() {
  size(2000, 200);
  textFont(createFont("Courier",18));
  background(255);

  /*for (int i=1;i<=20;i++)
    for (int j=i+1;j<=20;j++) {
      String fileA = "U1S"+Integer.toString(i)+".TXT";
      String fileB = "U1S"+Integer.toString(j)+".TXT";
      ArrayList<ArrayList<PVector>> strokesA = loadStrokes(fileA);
      ArrayList<ArrayList<PVector>> strokesB = loadStrokes(fileB);
      seqA = buildSymbolSequence(strokesA);
      seqB = buildSymbolSequence(strokesB);

      float rawDist = weightedMinEditDistance(seqA, seqB);
      //float normalized = rawDist / (seqA.size() + seqB.size());
      float normalized = rawDist / (calculateSize(seqA)+ calculateSize(seqB));

      println(fileA+"length: " + seqA.size()+"|| "+fileB+"length: " + seqB.size()+"|| Raw distance = " + nf(rawDist, 0, 3)+"|| Normalized distance = " + nf(normalized, 0, 3));
    }
    
  println("-------------------------------------------------------------------------------------------------------------------------------------------------");
  
  for (int i=1;i<=5;i++)
    for (int j=20+1;j<=40;j++) {
      String fileA = "U1S"+Integer.toString(i)+".TXT";
      String fileB = "U1S"+Integer.toString(j)+".TXT";
      ArrayList<ArrayList<PVector>> strokesA = loadStrokes(fileA);
      ArrayList<ArrayList<PVector>> strokesB = loadStrokes(fileB);
      seqA = buildSymbolSequence(strokesA);
      seqB = buildSymbolSequence(strokesB);

      float rawDist = weightedMinEditDistance(seqA, seqB);
      //float normalized = rawDist / (seqA.size() + seqB.size());
      float normalized = rawDist / (calculateSize(seqA)+ calculateSize(seqB));

      println(fileA+"length: " + seqA.size()+"|| "+fileB+"length: " + seqB.size()+"|| Raw distance = " + nf(rawDist, 0, 3)+"|| Normalized distance = " + nf(normalized, 0, 3));
    }*/
  ArrayList<ArrayList<PVector>> strokesA = loadStrokes(fileA);
  ArrayList<ArrayList<PVector>> strokesB = loadStrokes(fileB);
  
  seqA = buildSymbolSequence(strokesA);
  seqB = buildSymbolSequence(strokesB);

  float rawDist = weightedMinEditDistance(seqA, seqB);
  //float normalized = rawDist / (seqA.size() + seqB.size());
  float normalized = rawDist / (calculateSize(seqA)+ calculateSize(seqB));

  println("SeqA length: " + seqA.size());
  println("SeqB length: " + seqB.size());
  println("Raw distance        = " + nf(rawDist, 0, 3));
  println("Normalized distance = " + nf(normalized, 0, 3));

  drawSequences(seqA, seqB, rawDist, normalized);
}

int calculateSize(ArrayList<String> seqA) {
  int l = 0;
  for (String s : seqA)
    l += s.length();
    
  return l;
}

ArrayList<ArrayList<PVector>> loadStrokes(String filename) {
  String[] lines = loadStrings(filename);
  ArrayList<ArrayList<PVector>> strokes = new ArrayList<>();
  ArrayList<PVector> curr = new ArrayList<>();
  for (String ln : lines) {
    ln = trim(ln);
    if (ln.isEmpty())
      continue;
    String[] tok = splitTokens(ln);
    if (tok.length < 4)
      continue;
    int x = int(tok[0]), y = int(tok[1]), sid = int(tok[3]);
    if (sid == 0 && !curr.isEmpty()) {
      strokes.add(curr);
      curr = new ArrayList<>();
    }
    curr.add(new PVector(x, y));
  }
  if (!curr.isEmpty()) strokes.add(curr);
  return strokes;
}

ArrayList<String> buildSymbolSequence(ArrayList<ArrayList<PVector>> strokes) {
  
  ArrayList<String> seq = new ArrayList<>();
  for (ArrayList<PVector> stroke : strokes) {
    String str = "";
    if (stroke.isEmpty())
      continue;
    float xmin = stroke.get(0).x, xmax = xmin;
    float ymin = stroke.get(0).y, ymax = ymin;
    for (PVector p : stroke) {
      xmin = min(xmin, p.x);
      xmax = max(xmax, p.x);
      ymin = min(ymin, p.y);
      ymax = max(ymax, p.y);
    }
    for (PVector p : stroke) {
      if (p.x == xmin) 
        str += "A";
      if (p.x == xmax)
        str += "B";
      if (p.y == ymin)
        str += "C";
      if (p.y == ymax)
        str += "D";
    }
    seq.add(str);
  }
  return seq;
}

float weightedMinEditDistance(ArrayList<String> A, ArrayList<String> B) {
  int n = A.size(), m = B.size();
  float[][] D = new float[n+1][m+1];

  D[0][0] = 0;
  for (int i = 1; i <= n; i++) {
    D[i][0] = A.get(i-1).length();
  }
  for (int j = 1; j <= m; j++) {
    D[0][j] = B.get(j-1).length();
  }

  for (int i = 1; i <= n; i++) {
    String sA = A.get(i-1);
    int xCost = sA.length();
    for (int j = 1; j <= m; j++) {
      String sB = B.get(j-1);
      int yCost = sB.length();
      int diagCost = levenshteinDistanceString(sA, sB);

      float cDel = D[i-1][j]   + xCost;
      float cIns = D[i][j-1]   + yCost;
      float cSub = D[i-1][j-1] + diagCost;
      D[i][j] = min(cSub, min(cDel, cIns));
    }
  }
  return D[n][m];
}

int levenshteinDistanceString(String A, String B) {
  int n = A.length(), m = B.length();
  int[][] D = new int[n+1][m+1];
  for (int i = 1; i <= n; i++)
    D[i][0] = i;
  for (int j = 1; j <= m; j++)
    D[0][j] = j;
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      int cost = (A.charAt(i-1) == B.charAt(j-1)) ? 0 : 1;
      D[i][j] = min(
        D[i-1][j] + 1,
        min(D[i][j-1] + 1,
            D[i-1][j-1] + cost)
      );
    }
  }
  return D[n][m];
}

void drawSequences(ArrayList<String> A, ArrayList<String> B, float rawD, float normD) {
  fill(0);
  textAlign(LEFT, TOP);
  text("A: " + A, 10, 10);
  text("B: " + B, 10, 50);
  text("Adaptive Levenshtein Dist.   = " + nf(rawD, 0, 2), 10, 100);
  text("Normalized Levenshtein Dist.  = " + nf(normD, 0, 3), 10, 120);
}
