int fov = 250;
int DEFAULT_COLOR = 255;

float rad(float deg){
  return deg * PI/180;
}

float deg(float rad){
  return rad * 180/PI;
}

class Point{
  float x, y, z;
  String name = "";
  color col = color(255);
  Point(float x_, float y_, float z_){
    x = x_;
    y = y_;
    z = z_;
  }
  Point(float x_, float y_, float z_, String n_){
    x = x_;
    y = y_;
    z = z_;
    name = n_;
  }
  
  void move(float x_, float y_, float z_){
    x += x_;
    y += y_;
    z += z_;    
  }
  
  void draw(Camera camera){
    Direction dir = new Direction(camera.pos, this);
    float x_or = fov*tan(-dir.x() + camera.dir().x());
    float y_or = fov*tan(-dir.y() + camera.dir().y());
    fill(col);
    stroke(col);
    circle(x_or+(width/2), -y_or+(height/2), 5);
    text(name, x_or+(width/2)+10, -y_or+(height/2)+10);
    fill(DEFAULT_COLOR);
    stroke(DEFAULT_COLOR);
  }
}

class Direction{
  Point start, end;
  private float o, v;
  private boolean angle_mode = false;
  Direction(Point start_, Point end_){
    start = start_;
    end = end_;
  }
  Direction(Direction dir, Point p){
    start = dir.start;
    end = p;
  }
  Direction(float o_, float v_){
    angle_mode = true;
    o = o_;
    v = v_;
  }
  float y(){
    if(!angle_mode)return atan2(end.y - start.y, abs(end.x - start.x));
    else return v;
  }
  float x(){
    if(!angle_mode)return atan2(end.z - start.z, end.x - start.x);
    else return o;
  }
}


class Camera{
  Point pos;
  float o, v;
  Camera(Point p_, Point d_){
    pos = p_;
    Direction d = new Direction(pos, d_);
    o = d.x();
    v = d.y();
  }
  Direction dir(){
    return new Direction(o, v);
  }
  void move(float x, float y, float z){
    pos.move(x, y, z);
  }
  
  void rot(float o_, float v_){
    o += o_;
    v += v_;
  }
}


class Segment implements Comparable{
  Point p1, p2;
  Direction orientation;
  color col = color(DEFAULT_COLOR);
  Segment(float x1, float y1, float z1, float x2, float y2, float z2){
    p1 = new Point(x1, y1, z1);
    p2 = new Point(x2, y2, z2);
    orientation = new Direction(p1, p2);
  }
  Segment(Point p1_ , Point p2_){
    p1 = p1_;
    p2 = p2_;
    orientation = new Direction(p1, p2);
  }
  void setColor(color c_){
    col = c_;
  }
  
  void move(float x, float y, float z){
    p1.move(x, y, z);
    p2.move(x, y, z);
  }
  
  void draw(Camera camera){
    Direction s_dir = new Direction(camera.pos, p1);
    Direction e_dir = new Direction(camera.pos, p2);
    float s_x = fov*tan(s_dir.x() - camera.dir().x());
    float s_y = fov*tan(s_dir.y() - camera.dir().y());
    float e_x = fov*tan(e_dir.x() - camera.dir().x());
    float e_y = fov*tan(e_dir.y() - camera.dir().y());
    stroke(col);
    line(s_x+(width/2), -s_y+(height/2), e_x+(width/2), -e_y+(height/2));
    stroke(DEFAULT_COLOR);
  }
  float length(){
    return sqrt(pow(p1.x-p2.x,2) + pow(p1.y-p2.y,2) + pow(p1.z-p2.z,2));
  }
  Point middle(){
    return new Point((p1.x-p2.x)/2, (p1.y-p2.y)/2, (p1.z-p2.z)/2);
  }
  
  
  public int compareTo(Object s){
    float comp_len = ((Segment)s).length();
    float len = this.length();
    float ord = log(abs(len-comp_len));
    return int(len*pow(10, ord))-int(len*pow(10, ord));
  }
}

class Cube{
  Point origin;
  ArrayList<Point> vertexes = new ArrayList<Point>();
  ArrayList<Segment> corners = new ArrayList<Segment>();
  color vert_col, corn_col;
  boolean vert_vis = true, corn_vis = true;
  Cube(Point c_, float l, color col_){
    origin = c_;
    corn_col = col_;
    vert_col = col_;
    for(int i = 0; i < 2; i++){
      for(int j = 0; j < 2; j++){
        for(int k = 0; k < 2; k++){
          vertexes.add(new Point(i*l + origin.x, j*l + origin.y, k*l + origin.z));
          vertexes.get(vertexes.size() - 1).col = vert_col;
        }
      }
    }
    for(int i = 0; i < vertexes.size(); i++){
      for(int j = i; j < vertexes.size(); j++){
        print("");
        if(
            (vertexes.get(i).x == vertexes.get(j).x && vertexes.get(i).y == vertexes.get(j).y) ||
            (vertexes.get(i).x == vertexes.get(j).x && vertexes.get(i).z == vertexes.get(j).z) ||
            (vertexes.get(i).y == vertexes.get(j).y && vertexes.get(i).z == vertexes.get(j).z)
          ){
          corners.add(new Segment(vertexes.get(i), vertexes.get(j)));
          corners.get(corners.size() - 1).col = corn_col;
        }
      }
    }
  }
  void setVertexColor(color col_) { vert_col = col_; }
  void setCornerColor(color col_) { corn_col = col_; }
  void setVertexVisibility(boolean vis_) { vert_vis = vis_; }
  void setCornerVisibility(boolean vis_) { corn_vis = vis_; }
  
  void move(float x, float y, float z){
    for(int i = 0; i < vertexes.size(); i++){
      vertexes.get(i).move(x, y, z);
    }
    for(int i = 0; i < corners.size(); i++){
      corners.get(i).move(x, y, z);
    }
  }
  
  void draw(Camera camera){
    if(corn_vis){
      //sorting      
      ArrayList<Segment> corners_s = new ArrayList<Segment>();
      int added_c[] = new int[corners.size()];
      float distances[] = new float[corners.size()];
      int sorted_pos = 0;
      float max_dist_c = 0;
      int max_ind = -1;
      for(int i = 0; i < corners.size(); i++)distances[i] = (new Segment(camera.pos, corners.get(i).middle())).length();
      for(int i = 0; i < corners.size(); i++){
        if(max_dist_c < distances[i]){
          max_ind = i;
          max_dist_c = distances[i];
        }
      }
      added_c[sorted_pos] = max_ind;
      sorted_pos++;
      corners_s.add(corners.get(max_ind));
      boolean skip = false;
      while(true){
        if(corners_s.size() == corners.size())break;
        max_dist_c = 0;
        for(int i = 0; i < corners.size(); i++){
          for(int j = 0; j < corners.size(); j++){
            if(added_c[j] == i){
              skip = true;
              break;
            }
          }
          if(skip){
            skip = false;
            continue;
          }
          if(max_dist_c < distances[i]){
            max_dist_c = distances[i];
            max_ind = i;
          }
        }
        added_c[sorted_pos] = max_ind;
        sorted_pos++;
        corners_s.add(corners.get(max_ind));
      }
      
      // actual drawing
      for(int i = corners_s.size()-1; i > -1; i--){
        corners_s.get(i).draw(camera);
      }
    }
    if(vert_vis){
      // sorting
      ArrayList<Point> vertexes_s = new ArrayList<Point>();
      int added[] = new int[vertexes.size()];
      float distances[] = new float[vertexes.size()];
      int sorted_pos = 0;
      float max_dist = 0;
      int max_ind = -1;
      for(int i = 0; i < vertexes.size(); i++)distances[i] = (new Segment(camera.pos, vertexes.get(i))).length();
      for(int i = 0; i < vertexes.size(); i++){
        if(max_dist < distances[i]){
          max_ind = i;
          max_dist = distances[i];
        }
      }
      added[sorted_pos] = max_ind;
      sorted_pos++;
      vertexes_s.add(vertexes.get(max_ind));
      boolean skip = false;
      while(true){
        if(vertexes_s.size() == vertexes.size())break;
        max_dist = 0;
        for(int i = 0; i < vertexes.size(); i++){
          for(int j = 0; j < vertexes.size(); j++){
            if(added[j] == i){
              skip = true;
              break;
            }
          }
          if(skip){
            skip = false;
            continue;
          }
          if(max_dist < distances[i]){
            max_dist = distances[i];
            max_ind = i;
          }
        }
        added[sorted_pos] = max_ind;
        sorted_pos++;
        vertexes_s.add(vertexes.get(max_ind));
      }
      for(int i = vertexes.size()-1; i > -1; i--){
        vertexes_s.get(i).draw(camera);
      }
    }
  }
}


Point origin = new Point(0, 0, 0, "O");

Direction abs_dir(Point p){
  return new Direction(p, origin);
}

Point camera_pos = new Point(10, 0, 0);
Point camera_target = new Point(0, 0, 0);
Camera camera = new Camera(camera_pos, camera_target);
Cube cube = new Cube(new Point(2.5,-2.5,-2.5), 5, color(255,0,0));




int t_len = 8;
int c_len = 12;

void setup(){
  size(1000, 1000);
  background(0);
  fill(DEFAULT_COLOR);
  stroke(DEFAULT_COLOR);
  textSize(20);
  rectMode(CENTER);
  for(int i = 0; i < cube.corners.size(); i++){
    if(cube.corners.get(i).p1.x == -10 && cube.corners.get(i).p2.x == -10){
      cube.corners.get(i).col = color(0,255,0);
    }
  }
  strokeWeight(2);
}

int last_key;
boolean pressing = false;
void keyPressed() {
  pressing = true;
  last_key = keyCode;
}

void keyReleased() {
  pressing = false;
}


Direction cam_target;

void draw(){
  clear();
  if(pressing && last_key == LEFT){
    camera.move(0, 0, .1);
  }
  if(pressing && last_key == RIGHT){
    camera.move(0, 0, -.1);
  }
  if(pressing && last_key == UP){
    camera.move(0, .1, 0);
  }
  if(pressing && last_key == DOWN){
    camera.move(0, -.1, 0);
  }
  
  
  if(pressing && last_key == 96){
    camera.move(-.1, 0, 0);
  }
  if(pressing && last_key == 97){
    camera.move(.1, 0, 0);
  }
  
  
  if(pressing && last_key == 65){ //left
    camera.rot(-.01,0);
  }
  if(pressing && last_key == 68){ //right 
    camera.rot(.01, 0);
  }
  if(pressing && last_key == 87){ //up
    camera.rot(0, .01);
  }
  if(pressing && last_key == 83){ //down
    camera.rot(0, -.01);
  }
  
  
  
  
  
  if(pressing && last_key == 81){
    exit();
  }
  text(camera.dir().x() + "; " + camera.dir().y() + "; " + camera.o, 50, 100);
  
  origin.draw(camera);
  cube.draw(camera);
}
