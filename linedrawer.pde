import java.util.List;
Drawer drawer;
long last_millis;
boolean use_lines = true;
int rollover_time = 8 * 60 * 60 * 1000;
void settings() {
  fullScreen();
}

void setup() {
  if (args == null) {
    System.out.println("Please provide an images folder path");
    exit();
  }
  noCursor();
  imageMode(CENTER);
  StartNew();
}

void draw() {
  drawer.Draw();
  if (System.currentTimeMillis() - last_millis > rollover_time) {
    StartNew();
  }
}

void StartNew() {
  PImage ref = LoadImage();
  background(0,5,5);
  if( ref.width > ref.height ) {
    ref.resize(width, 0);
  }
  else {
    ref.resize(0, height);
  }

  drawer = use_lines ? new LineDrawer(ref) : new SquareDrawer(ref);
  last_millis = System.currentTimeMillis();;
}

PImage LoadImage() 
{
  String path = args[0];
  File[] files = listFiles(path);
  File f = files[ (int)random(files.length) ];
  PImage img = loadImage(f.getAbsolutePath());
  return img;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      StartNew();
    }
    else if( keyCode == UP) {
      use_lines = !use_lines;
      StartNew();
    }
  }
}

abstract class Drawer {
  PImage dirty;
  PImage ref;
  public Drawer( PImage ref) {
    this.ref = ref;
    this.dirty = createImage(ref.width, ref.height, RGB);
  }
  abstract List<PVector> GetShape(List<PVector> endpoints);
  abstract List<PVector> GetEndPoints();
  color GetColour(List<PVector> pixels) {
    PVector midPoint = pixels.get((int)random(0, pixels.size()));
    return ref.get((int)midPoint.x, (int)midPoint.y);
  }
  boolean ShouldDraw(List<PVector> line, color c, PImage dirty, PImage ref)
  {
    float curr_error = 0.0f;
    float new_error = 0.0f;

    for (PVector pt : line) {
      curr_error += Error( dirty.get( (int)pt.x, (int)pt.y), ref.get( (int)pt.x, (int)pt.y ) );
      new_error += Error( c, ref.get( (int)pt.x, (int)pt.y ) );
    }

    curr_error /= line.size();
    new_error /= line.size();
    
    return new_error <= curr_error;
  }

  void DrawPoints(List<PVector> pixels, color c) {
    for (PVector pt : pixels ) {
      dirty.set((int)pt.x, (int)pt.y, c);
    }
    image(dirty, width/2, height/2);
  }
  void Draw() {
    List<PVector> shape = GetShape(GetEndPoints());
    color c = GetColour(shape);
    if (ShouldDraw(shape, c, dirty, ref)) {
      DrawPoints(shape, c);
    }
  }
  float Error(color c1, color c2)
  {
    float redSquareError = (red(c1) * 1.0) - red(c2);
    redSquareError *= redSquareError;
    float greenSquareError = (green(c1) * 1.0) - green(c2);
    greenSquareError *= greenSquareError;
    float blueSquareError = (blue(c1) * 1.0) - blue(c2);
    blueSquareError *= blueSquareError;

    return (redSquareError + greenSquareError + blueSquareError) / 3.0f;
  }
}

class LineDrawer extends Drawer {

  public LineDrawer(PImage ref) {
    super(ref);
  }

  List<PVector> GetEndPoints() {
    PVector p1 = new PVector( random(dirty.width), random(dirty.height));

    int lowerx = p1.x - 250  < 0 ? 0 : (int)(p1.x - 250);
    int lowery = p1.y - 250  < 0 ? 0 : (int)(p1.y - 250);

    int upperx = p1.x + 250 > dirty.width ? dirty.width : (int)(p1.x + 250);
    int uppery = p1.y + 250 > dirty.height ? dirty.height : (int)(p1.y + 250);

    PVector p2 = new PVector( random(lowerx, upperx), random(lowery, uppery));
    List<PVector> points = new ArrayList<PVector>();
    points.add(p1);
    points.add(p2);
    return points;
  }

  //https://www.openprocessing.org/sketch/181477
  ArrayList<PVector> GetShape(List<PVector> endpoints)
  {
    PVector v0 = endpoints.get(0);
    PVector v1 = endpoints.get(1);

    ArrayList<PVector> pixels = new ArrayList<PVector>();
    int x0 = (int)v0.x;
    int y0 = (int)v0.y;
    int x1 = (int)v1.x;
    int y1 = (int)v1.y;
    boolean steep = false;
    if (abs(x0-x1)<abs(y0-y1))
    {
        int temp= x0;
        x0= y0;
        y0= temp;

        temp= x1;
        x1= y1;
        y1= temp;
        
        steep = true;
    }
    if (x0>x1)
    {
        int temp= x0;
        x0= x1;
        x1= temp;
        
        temp= y0;
        y0= y1;
        y1= temp;
    }
    int dx = x1-x0;
    int dy = y1-y0;
    int derror2 = abs(dy)*2;
    int error2 = 0;
    int y = y0;
    for (int x=x0; x<=x1; x++)
    {
        if (steep) 
        {
            pixels.add(new PVector(y, x));
        } 
        else 
        {
            pixels.add(new PVector(x, y));
        }
        error2 += derror2;

        if (error2 > dx) 
        {
            y += (y1>y0?1:-1);
            error2 -= dx*2;
        }
    }

    return pixels;
  }

  float Error(color c1, color c2)
  {
    float redSquareError = (red(c1) * 1.0) - red(c2);
    redSquareError *= redSquareError;
    float greenSquareError = (green(c1) * 1.0) - green(c2);
    greenSquareError *= greenSquareError;
    float blueSquareError = (blue(c1) * 1.0) - blue(c2);
    blueSquareError *= blueSquareError;

    return (redSquareError + greenSquareError + blueSquareError) / 3.0f;
  }

  boolean ShouldDraw(List<PVector> line, color c, PImage dirty, PImage ref)
  {
    float curr_error = 0.0f;
    float new_error = 0.0f;

    for (PVector pt : line) {
      curr_error += Error( dirty.get( (int)pt.x, (int)pt.y), ref.get( (int)pt.x, (int)pt.y ) );
      new_error += Error( c, ref.get( (int)pt.x, (int)pt.y ) );
    }

    curr_error /= line.size();
    new_error /= line.size();
    
    return new_error <= curr_error;
  }
}

class SquareDrawer extends Drawer {
  public SquareDrawer(PImage ref) {
    super(ref);
  }

  List<PVector> GetShape(List<PVector> endpoints)
  {
    List<PVector> points = new ArrayList<PVector>();

    PVector bottomLeft = new PVector(endpoints.get(0).x < endpoints.get(1).x ? endpoints.get(0).x : endpoints.get(1).x,
                       endpoints.get(0).y < endpoints.get(1).y ? endpoints.get(0).y : endpoints.get(1).y
    );
    PVector topRight = new PVector(endpoints.get(0).x > endpoints.get(1).x ? endpoints.get(0).x : endpoints.get(1).x,
                        endpoints.get(0).y > endpoints.get(1).y ? endpoints.get(0).y : endpoints.get(1).y
    );
    int sidelength = (int)Math.abs( topRight.x - bottomLeft.x);
    for (int x = (int)bottomLeft.x; x <= (int)topRight.x; x++ ) {
      for( int y = (int)bottomLeft.y; y <= (int)topRight.y; y++ ) {
        points.add(new PVector(x, y));
      }
    }

    return points;
  }
  List<PVector> GetEndPoints()
  {
    List<PVector> points = new ArrayList<PVector>();
    PVector p1 = new PVector( random(dirty.width), random(dirty.height));
    int sidelength = (int)random(30);
    int p2X = (int)(p1.x + sidelength >= dirty.width ? p1.x - sidelength : p1.x + sidelength);
    int p2Y = (int)(p1.y + sidelength >= dirty.height ? p1.y - sidelength : p1.y + sidelength);
    PVector p2 = new PVector( p2X, p2Y);
    points.add(p1);
    points.add(p2);

    return points;
  }
}
