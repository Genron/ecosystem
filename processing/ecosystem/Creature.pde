class Creature {
  PVector pos, vel, acc;
  static final float maxHealth = 10, birthCost = 3, starvation = 0.007, consumeRate = 0.014, reproductionProbability = 0.0002; // the same value for all creatures
  float health = random(maxHealth);
  float size;
  static final float maxSpeed = 10, maxAcc = maxSpeed*.1;
  NeuralNetwork brain;
  String name;
  int gen = 0, age = 0;
  float hue = random(360);
  boolean tooltip = false;
  ArrayList<Creature> children = new ArrayList();

  Creature(float size) {
    this.size = size;
    pos = new PVector(random(width), random(height));
    vel = new PVector();
    acc = new PVector();
    brain = new NeuralNetwork(53, 4, 3);
    // name consisting of three random letters
    this.name = "" + (char) ('a' + Math.random() * ('z'-'a' + 1)) + (char) ('a' + Math.random() * ('z'-'a' + 1)) + (char) ('a' + Math.random() * ('z'-'a' + 1));
  }

  Creature(NeuralNetwork brain, float size) {
    this(size);
    this.brain = brain;
  }

  Creature(float size, String name, int gen) {
    this(size);
    this.name = name;
    this.gen = gen;
  }

  void starve() {
    health -= starvation; // subtract base starvation
    health -= map(vel.mag(), 0, maxSpeed, 0, starvation*5); // additionally subtract some health based on movement speed
    //health -= map(vel.mag(), 0, maxSpeed, starvation*.5, starvation*.5*maxSpeed);
  }

  void steer(Terrain terrain) {
    float s = terrain.squareSize;
    int x = (int) (pos.x / s);
    int y = (int) (pos.y / s);
    Cell[][] g = terrain.ground;
    int cols = terrain.cols;
    int rows = terrain.rows;

    PVector mappedVel = vel.copy();
    mappedVel.setMag(map(mappedVel.mag(), 0, maxSpeed, 0, 1));

    float[] acc = brain.predict(new float[] {
      map(health, 0, maxHealth, 0, 1), 
      mappedVel.x, 
      mappedVel.y, 
      
      g[(y-2+rows)%rows][(x-2+cols)%cols].value, 
      g[(y-2+rows)%rows][(x-1+cols)%cols].value, 
      g[(y-2+rows)%rows][(x  +cols)%cols].value, 
      g[(y-2+rows)%rows][(x+1+cols)%cols].value, 
      g[(y-2+rows)%rows][(x+2+cols)%cols].value, 

      g[(y-1+rows)%rows][(x-2+cols)%cols].value, 
      g[(y-1+rows)%rows][(x-1+cols)%cols].value, 
      g[(y-1+rows)%rows][(x  +cols)%cols].value, 
      g[(y-1+rows)%rows][(x+1+cols)%cols].value, 
      g[(y-1+rows)%rows][(x+2+cols)%cols].value, 

      g[(y  +rows)%rows][(x-2+cols)%cols].value, 
      g[(y  +rows)%rows][(x-1+cols)%cols].value, 
      g[(y  +rows)%rows][(x  +cols)%cols].value, 
      g[(y  +rows)%rows][(x+1+cols)%cols].value, 
      g[(y  +rows)%rows][(x+2+cols)%cols].value, 

      g[(y+1+rows)%rows][(x-2+cols)%cols].value, 
      g[(y+1+rows)%rows][(x-1+cols)%cols].value, 
      g[(y+1+rows)%rows][(x  +cols)%cols].value, 
      g[(y+1+rows)%rows][(x+1+cols)%cols].value, 
      g[(y+1+rows)%rows][(x+2+cols)%cols].value, 

      g[(y+2+rows)%rows][(x-2+cols)%cols].value, 
      g[(y+2+rows)%rows][(x-1+cols)%cols].value, 
      g[(y+2+rows)%rows][(x  +cols)%cols].value, 
      g[(y+2+rows)%rows][(x+1+cols)%cols].value, 
      g[(y+2+rows)%rows][(x+2+cols)%cols].value, 


      g[(y-2+rows)%rows][(x-2+cols)%cols].baseValue, 
      g[(y-2+rows)%rows][(x-1+cols)%cols].baseValue, 
      g[(y-2+rows)%rows][(x  +cols)%cols].baseValue, 
      g[(y-2+rows)%rows][(x+1+cols)%cols].baseValue, 
      g[(y-2+rows)%rows][(x+2+cols)%cols].baseValue, 

      g[(y-1+rows)%rows][(x-2+cols)%cols].baseValue, 
      g[(y-1+rows)%rows][(x-1+cols)%cols].baseValue, 
      g[(y-1+rows)%rows][(x  +cols)%cols].baseValue, 
      g[(y-1+rows)%rows][(x+1+cols)%cols].baseValue, 
      g[(y-1+rows)%rows][(x+2+cols)%cols].baseValue, 

      g[(y  +rows)%rows][(x-2+cols)%cols].baseValue, 
      g[(y  +rows)%rows][(x-1+cols)%cols].baseValue, 
      g[(y  +rows)%rows][(x  +cols)%cols].baseValue, 
      g[(y  +rows)%rows][(x+1+cols)%cols].baseValue, 
      g[(y  +rows)%rows][(x+2+cols)%cols].baseValue, 

      g[(y+1+rows)%rows][(x-2+cols)%cols].baseValue, 
      g[(y+1+rows)%rows][(x-1+cols)%cols].baseValue, 
      g[(y+1+rows)%rows][(x  +cols)%cols].baseValue, 
      g[(y+1+rows)%rows][(x+1+cols)%cols].baseValue, 
      g[(y+1+rows)%rows][(x+2+cols)%cols].baseValue, 

      g[(y+2+rows)%rows][(x-2+cols)%cols].baseValue, 
      g[(y+2+rows)%rows][(x-1+cols)%cols].baseValue, 
      g[(y+2+rows)%rows][(x  +cols)%cols].baseValue, 
      g[(y+2+rows)%rows][(x+1+cols)%cols].baseValue, 
      g[(y+2+rows)%rows][(x+2+cols)%cols].baseValue 
      });
    this.acc.mult(0);
    this.acc.add(map(acc[0], 0, 1, -maxAcc, maxAcc), map(acc[1], 0, 1, -maxAcc, maxAcc));
  }

  void move() {
    pos.add(vel);
    pos.x = (pos.x + width) % width;
    pos.y = (pos.y + height) % height;
    vel.add(acc);
    vel.limit(maxSpeed);
  }

  void eat(Terrain terrain) {
    float s = terrain.squareSize;
    int x = (int) (pos.x / s) % terrain.cols;
    int y = (int) (pos.y / s) % terrain.rows;
    health += terrain.ground[y][x].consumeFood(consumeRate);
    health = min(health, maxHealth);
  }

  void displayOldest() {
    float opacity = map(health, 0, maxHealth*.75, 0, 255);
    stroke(0, 100, 100); // add a red border to the oldest creature
    strokeWeight(size*.2);
    displayCreature(opacity);
  }

  void displayYoungest() {
    float opacity = map(health, 0, maxHealth*.75, 0, 255);
    stroke(60, 100, 100, opacity); // add a yellow border to all creature with the youngest generation
    strokeWeight(size*.2);
    displayCreature(opacity);
  }

  void display() {
    noStroke();
    float opacity = map(health, 0, maxHealth*.75, 0, 255);
    displayCreature(opacity);
  }

  private void displayCreature(float opacity) {
    if(health < maxHealth*.1) {
      strokeWeight(size*.2);
      stroke(300, 100, 100, 120); // add a violet border on nearly dead creatures
    }
    
    fill(hue, 50, 100, opacity);
    ellipse(pos.x, pos.y, size, size);

    // display name and health
    float textSize = size/1.5; // scale with different screen sizes
    textSize(textSize);
    fill(0, opacity);
    String text = name + gen + ": " + floor(health*10);
    text(text, pos.x, pos.y-textSize*1.5);

    // display in which direction the creature is heading
    PVector v = vel.copy();
    v.setMag(size/3);
    noStroke();
    ellipse(pos.x+v.x, pos.y+v.y, size/5, size/5);
    //println(size);
  }

  void displayTooltip() {
    float textSize = size/1.25; // scale with different screen sizes
    textSize(textSize);
    textAlign(CENTER);
    // background rectangle
    noStroke();
    fill(0, 220);
    rect(pos.x-textSize*6, pos.y-textSize*11.75, textSize*12, textSize*11);
    
    fill(0, 0, 100);
    String text =
      "Name: " + name + "\n" +
      "Generation: " + gen + "\n" +
      "Age: " + floor(age/30.0) + "s" + "\n" +
      "Health: " + floor(health*10) + "/" + floor(maxHealth*10) + "\n" +
      "Speed: " + floor(vel.mag()*10) + "/" + floor(maxSpeed*10) + "\n" +
      "Acceleration: " + floor(acc.mag()*10) + "/" + floor(maxAcc*10) + "\n";
    text(text, pos.x, pos.y-textSize*9.75);
  }

  Creature reproduce() {
    if (health > birthCost*2 && random(10) < reproductionProbability * health) {
      health -= birthCost;

      Creature child = new Creature(size, name, gen+1);

      NeuralNetwork childsBrain = brain.copy();
      childsBrain.mutate(.5, .3);
      child.brain = childsBrain;

      child.hue = (hue + random(-2, 2))%360;
      child.pos.x = this.pos.x;
      child.pos.y = this.pos.y;
      child.health = this.health;

      children.add(child);

      return child;
    }
    return null;
  }

  // default save: saves the creatures neural network. Path: just the name and gen of the creature
  void save() {
    brain.save(name + gen + ".txt");
  }
  void save(String savePath) {
    brain.save(savePath);
  }
}
