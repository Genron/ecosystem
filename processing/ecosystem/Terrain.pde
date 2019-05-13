class Terrain {
  int squareSize, cols, rows;
  float noise; // value between 0-100. Defines how "uneven" the terrains terrain will be. A large number means a very noisy terrain
  static final float biomass = 1.0; // the amount of food a creature leaves on a cell when it dies.

  float[] borders;
  float[][] hsb = {  // hsb color values for environment
    { 220, 100,  15 }, // black
    { 180,  70,  60 }, // blue
    { 100,  80,  80 }, // green
    {  60,  10,  90 }, // yellowish
    {   0,   0, 100 }  // white
  };
  Cell[][] ground;

  Terrain() {
    this(18, 35, new float[]{ .25, .45, .7, .75 }); // default values for empty constructor
  }

  Terrain(int squareSize, int noise, float[] borders) {
    this.squareSize = squareSize;
    this.noise = map(noise, 0, 100, 0, .1); // mapping the noise value to a more reasonable. In terms of user experience I'd like to hand over a value between 0-100 in the constructor
    this.borders = borders;
    cols = width / squareSize;
    rows = height / squareSize;
    ground = new Cell[rows][cols];
    reset(); // initial setup of cells on the grid
  }

  // based on the given parameters, a grid full of cells is created. Creates cols * rows cells.
  void reset() {
    float zOff = random(100000); // random position in 3-dimensional noise space (more information about noise later on in this method)
    for (int y=0; y<rows; y++) { // iterate over all positions and create there a new cell
      for (int x=0; x<cols; x++) {
        // you can imagine noise as a n-dimensional space filled with random values, but if you pick two "locations" near each other, you get somewhat similar values
        // for more information about noise have a look at the processing documentation
        float pos = noise(x*noise, y*noise, zOff); // value between 0-1
        pos = map(pos, 0, 1, -.2, 1.2); // scale a little, since we're getting the values 0/1 relatively rare
        pos = min(0.99, max(0.01, pos)); // constrain to 0/1
        
        float h=0, s=0, b=0; // hue, saturation and brightness of the terrain
        float value = 0; // the potential amount of food available on the cell 
        float idealEnvironmentPosition = (borders[1] + borders[2]) / 2; // range from end of water to end of grass: eg. (0.4+0.6)/2=0.5 -> there is 100% food

        // check the value of each field: Define the potential amount of food and set its color according to it's food potential
        // no transition: deep ocean ocean, range from 0 - 0.25
        if (pos <= borders[0]) {
          value = map(pos, 0, borders[0], 0, .2);
          h = hsb[0][0]; // black
          s = hsb[0][1];
          b = hsb[0][2];

          // transition of deep ocean to end of ocean, range from 0.25 - 0.45
        } else if (borders[0] >= 0 && pos <= borders[1]) {
          float minFood = .2, maxFood = .5;
          value = map(pos, borders[0], borders[1], minFood, maxFood);
          h = map(value, minFood, maxFood, hsb[0][0], hsb[1][0]); // 0 -> black / 1 -> blue
          s = map(value, minFood, maxFood, hsb[0][1], hsb[1][1]); // gradient from black to blue
          b = map(value, minFood, maxFood, hsb[0][2], hsb[1][2]); // 0.2 food = black, 0.5 food = blue

          // transition of end of ocean to center of grass, eg. 0.45 - 0.575 ((0.45+0.7)/2)
        } else if (pos > borders[1] && pos <= idealEnvironmentPosition) {
          float minFood = .5, maxFood = 1;
          value = map(pos, borders[1], idealEnvironmentPosition, minFood, maxFood);
          h = map(value, minFood, maxFood, hsb[1][0], hsb[2][0]); // 1 -> blue / 2 -> green
          s = map(value, minFood, maxFood, hsb[1][1], hsb[2][1]); // gradient from blue to green
          b = map(value, minFood, maxFood, hsb[1][2], hsb[2][2]); // 0.5 food = blue, 1 food = green

          // transition of center of grass to beginning of savanne, eg. 0.575 - 0.7
        } else if (pos > idealEnvironmentPosition && pos <= borders[2]) {
          float maxFood = 1, minFood = .5;
          value = map(pos, idealEnvironmentPosition, borders[2], maxFood, minFood);
          h = map(value, maxFood, minFood, hsb[2][0], hsb[3][0]); // 2 -> green / 3 -> yellowish
          s = map(value, maxFood, minFood, hsb[2][1], hsb[3][1]); // gradient from to green to yellow
          b = map(value, maxFood, minFood, hsb[2][2], hsb[3][2]); // 1 food = green, 0.5 food = yellow          

          // transition of begin of savanne to begin of desert, range from 0.7 - 0.75
        } else if (pos > borders[2] && pos <= borders[3]) {
          float maxFood = .5, minFood = .2;
          value = map(pos, borders[2], borders[3], maxFood, minFood);
          h = map(value, maxFood, minFood, hsb[3][0], hsb[4][0]); // 2 -> green / 3 -> yellow
          s = map(value, maxFood, minFood, hsb[3][1], hsb[4][1]); // gradient from green to yellow
          b = map(value, maxFood, minFood, hsb[3][2], hsb[4][2]); // 0.5 food = yellow, 0.2 food = white
          
          // no transition: desert, range from 0.75 - 1.0
        } else if (pos > borders[3]) {
          value = map(pos, borders[3], 1, .2, 0);
          h = hsb[4][0]; // white
          s = hsb[4][1];
          b = hsb[4][2];
        }
        ground[y][x] = new Cell(x, y, squareSize, value, h, s, b); // create a new cell at location x/y
      }
    }
  }

  // when a creature dies, it leaves some food on the cell it dies on. Add +1 to the cell at the creatures location
  void putBiomass(Creature creature) {
    int x = (int) (creature.pos.x / squareSize) % cols;
    int y = (int) (creature.pos.y / squareSize) % rows;  
    ground[y][x].value += biomass;
  }

  // displays each cell of the terrain
  void display() {
    textAlign(CENTER, CENTER);
    textSize((float) squareSize/2);
    for (int y=0; y<ground.length; y++) {
      for (int x=0; x<ground[y].length; x++) {
        ground[y][x].display();
      }
    }
  }

  // for each cell on the grid: update its value. Update means: adjust its current food value until the value reaches the potential amount of food. This is the aequivalent to grow food / decay dead creatures.
  void update() {
    for (int y=0; y<ground.length; y++) {
      for (int x=0; x<ground[y].length; x++) {
        ground[y][x].update();
      }
    }
  }
}
