ArrayList<Creature> creatures = new ArrayList(); // all of the creatures that are currently alive
ArrayList<Creature> survivors = new ArrayList(); // some of the creatures that died this generation will pass their "brain" onto the next generation
int speed = 1; // simulation speed
int generation = 0; // generation count: keeps track of "youngest" generation
boolean play = true; // play/pause the simulation
boolean display = true; // performance wise: controls whether to update (display) the view 

// TERRAIN SETTINGS
Terrain terrain;
int terrainSquareSize = 20; // defines how large the map is. The smaller the square size, the larger the map
int terrainNoise = 40; // value between 0-100. Defines how "uneven" the terrains terrain will be. A large number means a very noisy terrain
float[] terrainBordersModerate = { // defines the "borders" of the environment in a range between 0-1
  .22, //  0  - .25 = deep ocean
  .42, // .25 - .45 = ocean
  .7, // .45 - .7  = grass
  .75, // .7  - .75 = savanne
};     // .75 -  1  = desert
float[] terrainBordersEasy = { // defines the "borders" of the environment in a range between 0-1
  .07, //  0  - .25 = deep ocean
  .27, // .25 - .45 = ocean
  .85, // .45 - .7  = grass
  .9, // .7  - .75 = savanne
};     // .75 -  1  = desert
float[] terrainBordersHard = { // defines the "borders" of the environment in a range between 0-1
  .32, //  0  - .25 = deep ocean
  .52, // .25 - .45 = ocean
  .62, // .45 - .7  = grass
  .68, // .7  - .75 = savanne
};     // .75 -  1  = desert

int startPop = 100; // starting population
String pathToNeuralNet = "yja1.txt"; // neural network, the 'brain' base for each creature in the starting population

// HEATMAP SETTINGS
Heatmap heatmap = new Heatmap();
boolean displayHeatmap = false;
int heatmapDetail = 15;

void setup() {
  size(1600, 900); // alternatively display simulation in window
  //fullScreen();

  terrain = new Terrain(terrainSquareSize, terrainNoise, terrainBordersModerate); // Setting up a new environment for the creatures
  reset(); // Initially reset both, terrain and creatures

  noStroke();
  colorMode(HSB, 360, 100, 100);
  frameRate(30);
}

void draw() {
  // CALCULATIONS
  for (int l=0; play && l<speed; l++) { // while play is set to true -> make 'speed' times calculations
    terrain.update();
    for (int i=creatures.size()-1; i>=0; i--) { // iterate backwards through creatures, since some of them will probably die and will be removed from the list
      Creature creature = creatures.get(i);
      creature.starve();
      creature.age++;
      if (creature.health <= 0) { // if the health of a creature is 0 or less it dies. Maybe add it to the survivors (pass genes to next generation) and remove it from the list
        if (random(1) < 1./creatures.size()) { // the less creatures are in the list, the higher the probability to pass over the genes
          survivors.add(creature);
        }
        creatures.remove(creature);
        terrain.putBiomass(creature); // add some 'food' to the cell where the creature dies
      } else {
        creature.steer(terrain); // the creature decides in which direction to go (neural network part)
        creature.move();
        creature.eat(terrain); // eat some food at current location
        Creature child = creature.reproduce(); // with some chance -> clone and mutate the creature
        if (child != null) {
          creatures.add(child); // the new creature will not be updated in this drawing cycle, but next
          generation = max(generation, child.gen); // update the generation count (keep always the largest one)
        }
      }
    }
  }

  // reset automatically if all, but one creatures are dead
  if (creatures.size() <= 1) {
    for (Creature left : creatures) {
      survivors.add(left);
    }
    resetCreatures(); // reset only creatures -> terrain stays the same
  }

  // DRAWING STUFF
  if (display) { // update visual simulation only when boolean 'display' set to true (performance boost for training)
    background(0);
    if (displayHeatmap) { // in case the boolean 'displayHeatmap' is also set to true, then display the heatmap visualization instead 
      //heatmap.displayRectangles(heatmapDetail, creatures); // other visualization option
      heatmap.displayCircles(heatmapDetail, creatures);
    } else {
      terrain.display();
      Creature oldest = creatures.get(0);
      oldest.displayOldest(); // display oldest creature (the first creature from the list is also alway the oldest one) with a red border
      for (int i=1; i<creatures.size(); i++) { // display all other creatures
        Creature creature = creatures.get(i);
        if (creature.gen == generation) { // if the creatures gen attribute appears to be the same as the youngest generation, display it with a yellow border
          creature.displayYoungest();
        } else {
          creature.display();
        }
      }

      for (Creature creature : creatures) { // if the boolean 'tooltip' of a creature is set to true, or if the cursor is in range of a creature, display a tooltip
        float range = 20;
        boolean tooltip = abs(creature.pos.x - mouseX) <= range && abs(creature.pos.y - mouseY) <= range; // check if the cursor is within range of the creature
        // if the creature has a tooltip toggled or if the mouse cursor is in range of the creature
        if (creature.tooltip || tooltip) {
          creature.displayTooltip();
        }
      }

      showStatsOnScreen(); // display the info box in top left corner
    }
  }
}

// METHODS
void resetCreatures() { // clears all existing creatures and starts a new population
  creatures.clear();
  if (survivors.size() != 0) { // if there are any survivors in the list (list is empty on program startup)
    float maxAge = 0; // calculate sum of all survivors age: eg. 44'225 seconds == 100%
    for (Creature s : survivors) {
      maxAge += s.age;
    }
    // calculate the 'weight' one second has over all new population.
    // defines later on how many offsprings of a creature will be added to the new population.
    // eg. 255 creatures / 44'225 seconds = 0.0023 => 1 creature == 0.0023%
    float percentage = startPop / maxAge;
    for (Creature s : survivors) {
      // calculate for each creature, how many children are produced from its brain (but 1 creature at least).
      // eg. 0.0023% * 185 seconds = 0.42 creatures => max(1, 0.42) = 1 => 1 creature will be added
      // or 0.0023% * 6957 seconds = 16.001 creatures => max(1, 16.001) = 16 => 16 creatures will be added
      int adding = (int)max(1, percentage * s.age);
      creatures.add(s);
      for (int j=0; j<adding; j++) { // for the calculated amount of creatures: add a mutated child to the new population
        NeuralNetwork newBrain = s.brain.copy();
        newBrain.mutate(.5, .3); // mutate the brain, so that we don't have a population with all the same creatures
        creatures.add(new Creature(newBrain, terrainSquareSize * .8));
      }
    }
    survivors.clear();
  } else if (pathToNeuralNet == null || pathToNeuralNet == "") { // if there is no reference to a neural network as brain, create a new "stupid" population
    //println("Starting blank new population");
    for (int i=0; i<startPop; i++) {
      creatures.add(new Creature(terrainSquareSize * .8)); // make the creatures 80% of the size of a square in the terrain
    }
  } else { // if there is a reference to a neural network as brain, create a new population based on the existing neural network
    //println("Starting new population from creature: " + pathToNeuralNet);
    NeuralNetwork brain = new NeuralNetwork(pathToNeuralNet);
    creatures.add(new Creature(brain, terrainSquareSize * .8)); // add the "original" creature to the population
    for (int i=0; i<startPop-1; i++) { // for all other creatures in the population
      NeuralNetwork newBrain = brain.copy();
      newBrain.mutate(.5, .3); // mutate the brain, so that we don't have a population with all the same creatures
      creatures.add(new Creature(newBrain, terrainSquareSize * .8));
    }
  }
  //println("Successfully resetted the creatures");
}

// resets only the terrain the creatures live on. Simulating a drastic change of environment
void resetTerrain() {
  terrain.reset();
  //println("Successfully resetted the terrain");
}

// resets both, creatures and the terrain. starts simulation from beginning.
void reset() {
  resetTerrain();
  resetCreatures();
}

// displays the amount of creatures and its average health to left in the corner
void showStatsOnScreen() {
  float textSize = terrainSquareSize/1.25; // scale with different screen sizes
  // background rectangle
  noStroke();
  fill(0, 0, 100, 150);
  rect(0, 0, textSize * 13.5, textSize * 4.25);
  fill(0);
  textSize(textSize);
  textAlign(LEFT, CENTER);
  // compute average
  float h = 0;
  for (Creature creature : creatures) {
    h += creature.health;
  }
  // display info text
  text("creatures: " + creatures.size(), textSize, textSize);
  text("average health: " + floor(h/creatures.size()*10)+"/"+floor(Creature.maxHealth*10), textSize, textSize*2.5);
}

// saves the creature with the highest generation
void saveBestGen() {
  Creature bestGenCreature = creatures.get(0);
  for (Creature creature : creatures) {
    if (creature.gen > bestGenCreature.gen) {
      bestGenCreature = creature;
    }
  }
  bestGenCreature.save();
  println(bestGenCreature.name + bestGenCreature.gen + ".txt" + " saved!");
}

void mouseReleased() {
  // toggle tooltip on a creature
  for (Creature creature : creatures) {
    float range = 20;
    boolean t = abs(creature.pos.x - mouseX) <= range && abs(creature.pos.y - mouseY) <= range;
    if (t) {
      creature.tooltip = !creature.tooltip;
    }
  }
}

void keyPressed() {
  switch(keyCode) {
  case 32:
    // 'space'
    play = !play;
    println(play ? "Resumed" : "Paused");
    break;
  case 38:
    if (displayHeatmap) {
      heatmapDetail += 1;
      println("heatmapDetail: " + heatmapDetail);
    } else {
      speed += 1;
      println("speed: " + speed);
    }
    break;
  case 40:
    if (displayHeatmap) {
      heatmapDetail = max(1, heatmapDetail-1);
      println("heatmapDetail: " + heatmapDetail);
    } else {
      speed = max(0, speed-1);
      println("speed: " + speed);
    }
    break;
  case 67:
    // 'c'
    resetTerrain();
    break;
  case 68:
    // 'd'
    display = !display;
    break;
  case 72:
    // 'h'
    displayHeatmap = !displayHeatmap;
    break;
  case 82:
    // 'r'
    survivors.clear(); // needed, since we want to start from scratch and do not want any survivors
    reset();
    break;
  case 83:
    // 's'
    saveBestGen();
    break;
  case 84:
    // 't'
    for (Creature creature : creatures) {
      creature.tooltip = false;
    }
    break;
  case 49:
  case 97:
    // '1'
    speed = 1;
    println("speed: " + speed);
    break;
  case 50:
  case 98:
    // '2'
    speed = 10;
    println("speed: " + speed);
    break;
  case 51:
  case 99:
    // '3'
    speed = 100;
    println("speed: " + speed);
    break;
  default:
    println("keyCode: " + keyCode);
  }
}
