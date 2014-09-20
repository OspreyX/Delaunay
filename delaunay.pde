class Point2D {
  float x, y;

  Point2D (final float x, final float y) {
    this.x = x;
    this.y = y;
  }

  float disTo (final Point2D point) {
    return (float)sqrt((point.x-x)*(point.x-x)+(point.y-y)*(point.y-y));
  }
}

class Vector2D {
  PVector v;

  Vector2D (final Point2D A, final Point2D B) {
    v = new PVector(B.x-A.x, B.y-A.y);
  }
  
  Vector2D (final float x, final float y, final float z) {
    v = new PVector(x,y,z);
  }
  
  float dot (final Vector2D point) {
    return v.x*point.v.x + v.y*point.v.y;
  }
  
  void normalize() {
    final float factor = sqrt(v.x*v.x+v.y*v.y+v.z*v.z);
    v.x /= factor;
    v.y /= factor;
    v.z /= factor;    
  }
  
  void left() {
    float tmp = v.x;
    v.x = -v.y;
    v.y = tmp;
  }
  
  void scaleBy (final float factor) {
    v.x*=factor;
    v.y*=factor;
  }
}

// corner table again!!
final int SCREEN_SIZE = 800;
final int MAX_STUFF = 6000;
int nt = 0;
int nv = 0;
int nc = 0;

// circumcenters;
Point2D[] cc = new Point2D[MAX_STUFF];
boolean hasCC = false;
boolean bRenderCC = true;
float[] cr = new float[MAX_STUFF];

// V Table
int[] V = new int[MAX_STUFF];
int[] C = new int[MAX_STUFF*3];
boolean[] visited = new boolean[MAX_STUFF*3];

// G Table
Point2D[] G = new Point2D[MAX_STUFF];

// O-Table
int[] O = new int[MAX_STUFF];


int t (final int idx) {
  return floor(idx/3);
}

int v (final int idx) {
  return V[idx];
}

int o (final int idx) {
  return O[idx];
}

int n (final int c) {
  if (c%3 == 2) {
    return c-2;
  }

  return c+1;
}

int p (final int c) {
  if (c%3 == 0) {
    return c+2;
  }

  return c-1;
}

int g (final int triangleIndex) {
  return V[triangleIndex*3];
}

int gn (final int triangleIndex) {
  return V[n(triangleIndex)];
}

int gp (final int triangleIndex) {
  return V[p(triangleIndex)];
}

float dot (final Vector2D v1, final Vector2D v2) {
  return v1.dot(v2);
}

// result is the Z component of 3D cross
float cross2D (final Vector2D U, final Vector2D V) {
  return U.v.x*V.v.y - U.v.y*V.v.x;
}

boolean isLeftTurn (final Point2D A, final Point2D B, final Point2D C) {
  if (cross2D(new Vector2D(A, B), new Vector2D(B, C)) > 0) {
    return true;
  }

  return false;
}

boolean isInTriangle (final int triangleIndex, final Point2D P) {
  final int c = triangleIndex*3;

  Point2D A = G[v(c)];
  Point2D B = G[v(n(c))];
  Point2D C = G[v(p(c))];

  if (isLeftTurn(A,B,P) == isLeftTurn(B,C,P) && isLeftTurn(A,B,P) == isLeftTurn(C,A,P)) {
    return true;
  }

  return false;
}

void initTriangles() {
  G[0] = new Point2D(0,0);
  G[1] = new Point2D(0,SCREEN_SIZE);
  G[2] = new Point2D(SCREEN_SIZE, SCREEN_SIZE);
  G[3] = new Point2D(SCREEN_SIZE, 0);

  nv = 4;

  V[0] = 0;
  V[1] = 1;
  V[2] = 2;
  V[3] = 2;
  V[4] = 3;
  V[5] = 0;  

  nt = 2;
  nc = 6;

  buildOTable();
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    addPoint(mouseX, mouseY);
    
    if(bRenderCC) {
      computeCC();
    }
    
    return;
  }

  if (mouseButton == RIGHT) {
    if (!bRenderCC) {
      computeCC();
    }
    bRenderCC = !bRenderCC;
  }
}

class Triplet {
  int a, b, c;
  
  Triplet (final int a, final int b, final int c) {
    this.a = a;
    this.b = b;
    this.c = c;
  }
  
  Triplet (final Triplet rhs) {
    this.a = rhs.a;
    this.b = rhs.b;
    this.c = rhs.c;
  }  
  
  boolean isLessThan (final Triplet rhs) {
    if( a < rhs.a ) {
      return true;
    }
    else if( a == rhs.a ) {
      if( b < rhs.b ) {
        return true;
      }
      else if( b == rhs.b ) {
        if( c < rhs.c ) {
          return true;
        }
      }
      else {
        return false;
      }
    }
    return false;
  }
};


ArrayList concatenate (ArrayList left, Triplet val, ArrayList right) {
  ArrayList ret = new ArrayList();
  for( int i = 0; i < left.size(); ++i )
    ret.add((Triplet)left.get(i));
  
  ret.add(val);
  
  for( int i = 0; i < right.size(); ++i )
    ret.add((Triplet)right.get(i));
    
  return ret;
}


ArrayList naiveQSort (ArrayList stuff)
{
  if( stuff.size() <= 1 ) {
    return stuff;
  }
  
  int pivotIdx = round(stuff.size()/2);
  
  Triplet pivot = (Triplet)stuff.get(pivotIdx);

  ArrayList left = new ArrayList();
  ArrayList right = new ArrayList();  

  for (int i = 0; i < stuff.size(); ++i) {
    if (i == pivotIdx) {
      continue;
    }
    
    Triplet cur = (Triplet)stuff.get(i);
    if (cur.isLessThan(pivot)) {
      left.add(new Triplet(cur));
    }
    else {
      right.add(new Triplet(cur));
    }      
  }
  return concatenate(naiveQSort(left), pivot, naiveQSort(right));
}

void buildOTable() {
  for (int i = 0; i < nc; ++i) {
    O[i] = -1;
  }

  ArrayList vtriples = new ArrayList();
  for(int ii=0; ii<nc; ++ii) {
    int n1 = v(n(ii));
    int p1 = v(p(ii));
    
    vtriples.add(new Triplet(min(n1,p1), max(n1,p1), ii));
  }

  ArrayList sorted = new ArrayList();
  sorted = naiveQSort(vtriples);

  // just pair up the stuff
  for (int i = 0; i < nc-1; ++i) {
    Triplet t1 = (Triplet)sorted.get(i);
    Triplet t2 = (Triplet)sorted.get(i+1);
    if (t1.a == t2.a && t1.b == t2.b) {
      O[t1.c] = t2.c;
      O[t2.c] = t1.c;
      i+=1;
    }
  }
}


Point2D intersection (Point2D S, Point2D SE, Point2D Q, Point2D QE) {
  Vector2D T = new Vector2D(S, SE);
  Vector2D N = new Vector2D(Q, QE);
  N.normalize();
  N.left();
  Vector2D QS = new Vector2D(Q, S);
  
  float QS_dot_N = dot(QS,N);
  float T_dot_N = dot(T,N);
  float t = -QS_dot_N/T_dot_N;
  T.scaleBy(t);
  return new Point2D(S.x+T.v.x,S.y+T.v.y);
}


void computeCC() {
  hasCC = false;
  
  for (int i = 0; i < nt; ++i) {
    int c = i*3;
    cc[i] = circumCenter(G[v(c)],G[v(c+1)],G[v(c+2)]);
    cr[i] = (float)G[v(c)].disTo(cc[i]);
  }
  hasCC = true;
}

void renderCC() {
  if (!hasCC) {
    return;
  }

  stroke(255,0,0);
  noFill();
  strokeWeight(1.0);

  for (int i = 3; i < nt; ++i) {
    stroke(0,0,255);
    fill(0,0,255);
    ellipse(cc[i].x, cc[i].y, 5,5);
    stroke(255,0,0);
    noFill();  
    ellipse(cc[i].x, cc[i].y, cr[i]*2, cr[i]*2);
  }
    
  stroke(0,0,0);
  noFill();
}

Point2D midPoint2D (final Point2D A, final Point2D B) {
  return new Point2D( (A.x + B.x)/2, (A.y + B.y)/2 );
}

Point2D circumCenter (final Point2D A, final Point2D B, final Point2D C) {
  Point2D midAB = midPoint2D(A,B);
  Vector2D AB = new Vector2D(A,B);
  AB.left();
  AB.normalize();
  AB.scaleBy(-1);

  Point2D midBC = midPoint2D(B,C);
  Vector2D BC = new Vector2D(B,C);
  BC.left();
  BC.normalize();
  BC.scaleBy(-1);  

  float fact = 100;

  Point2D AA = new Point2D( midAB.x+AB.v.x*fact, midAB.y+AB.v.y*fact);
  Point2D BB = new Point2D( midAB.x-AB.v.x*fact, midAB.y-AB.v.y*fact);
  Point2D CC = new Point2D( midBC.x+BC.v.x*fact, midBC.y+BC.v.y*fact);
  Point2D DD = new Point2D( midBC.x-BC.v.x*fact, midBC.y-BC.v.y*fact);
  return intersection(AA, BB, CC, DD);  
}

boolean naiveCheck (final float radius, final Point2D cc, final int c) {
  int A = v(c);

  if (G[A].disTo(cc) < radius) {
    return false;
  }

  return true;
}

boolean isDelaunay (int c) {
 // $$$FIXME : reuse precomputed cc and cr
  Point2D center = circumCenter(G[v(c)], G[v(n(c))], G[v(p(c))]);
  float radius = (float)G[v(c)].disTo(center);
  return( naiveCheck(radius, center, o(c)) );
}

void flipCorner (int c) {
  if( c == -1 ) {
    return;
  }

  buildOTable();    

  // boundary, do nothing..
  if( o(c) == -1 ) {
    return;
  }

  if(!isDelaunay(c)) {
    int opp = o(c);
    
    V[n(c)] = V[opp];    
    V[n(opp)] = V[c];

    buildOTable();
    flipCorner(c);
    buildOTable();
    flipCorner(n(opp));
  }
}


void fixMesh(ArrayList l) {
  buildOTable();

  while (!l.isEmpty()) {
    final int c = (Integer)l.get(0);
    flipCorner(c);
    l.remove(0);
  }
}


void addPoint(final float x, final float y) {
  G[nv] = new Point2D(x, y);
  ++nv;

  final int currentNumberOfTriangles = nt;
  for (int triangleIndex = 0; triangleIndex < currentNumberOfTriangles; ++triangleIndex) {
    if (isInTriangle(triangleIndex, G[nv-1])) {
      final int A = triangleIndex*3;
      final int B = A+1;
      final int C = A+2;

      V[nt*3]   = v(B);
      V[nt*3+1] = v(C);
      V[nt*3+2] = nv-1;

      V[nt*3+3] = v(C);
      V[nt*3+4] = v(A);
      V[nt*3+5] = nv-1;

      V[C] = nv-1;
      
      ArrayList dirtyCorners = new ArrayList();
      final int d1 = C;
      final int d2 = nt*3+2;
      final int d3 = nt*3+5;
      dirtyCorners.add(d1);
      dirtyCorners.add(d2);
      dirtyCorners.add(d3);

      nt += 2;
      nc += 6;
      fixMesh(dirtyCorners);
      break;
    }
  }
}

void drawTriangles() {
  noFill();
  strokeWeight(1.0);
  stroke(0,255,0);

  for (int i = 0; i < nt; ++i) {
    final int c = i*3;
    final Point2D A = G[v(c)];
    final Point2D B = G[v(n(c))];
    final Point2D C = G[v(p(c))];
    triangle(A.x, A.y, B.x, B.y, C.x, C.y);
  }

  strokeWeight(5.0);
  for (int i = 0; i < nv; ++i) {
    point(G[i].x, G[i].y);
  }
}

void setup() {
  size(SCREEN_SIZE, SCREEN_SIZE);
  smooth(); 
  initTriangles();
}

void draw() {
  background(0);

  pushMatrix();
    drawTriangles();
    if( bRenderCC )
      renderCC();
  popMatrix();
}
