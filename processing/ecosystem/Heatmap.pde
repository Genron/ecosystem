class Heatmap {
  float wid, hei;
  CreatureStore[][] grid;
  int hottest, detail;

  private void setupData(int detail, ArrayList<Creature> creatures) {
    hottest = 0;
    wid = 1.0 * width / detail; // 1000px / 10 => 100px width
    hei = 1.0 * height / detail;
    grid = new CreatureStore[detail][detail]; // 10x10 grid
    for (int i=0; i<grid.length; i++) {  
      for (int j=0; j<grid[i].length; j++) {
        grid[i][j] = new CreatureStore();
      }
    }
    for (Creature c : creatures) {
      // 1000 / 100 = 10 => 10 squares
      // position at 127 => 127 / 100 = 1.27 => at index 1
      int x = (int)(c.pos.x / wid);
      int y = (int)(c.pos.y / hei);
      try {
        grid[y][x].creatures.add(c);
        hottest = max(hottest, grid[y][x].creatures.size());
      } 
      catch (ArrayIndexOutOfBoundsException e) {
        //println(e);
      }
    }
  }

  void displayRectangles(int detail, ArrayList<Creature> creatures) {
    setupData(detail, creatures);
    noStroke();
    for (int y=0; y<grid.length; y++) {
      for (int x=0; x<grid[y].length; x++) {
        CreatureStore heat = grid[y][x];
        fill(335, 100, map(heat.creatures.size(), 0, hottest, 0, 100));
        rect(x*wid, y*hei, wid, hei);
      }
    }
  }

  void displayCircles(int detail, ArrayList<Creature> creatures) {
    setupData(detail, creatures);
    noStroke();
    for (int y=0; y<grid.length; y++) {
      for (int x=0; x<grid[y].length; x++) {
        CreatureStore heat = grid[y][x];
        float avgX = 0;
        float avgY = 0;
        for (Creature c : heat.creatures) {
          avgX += c.pos.x;
          avgY += c.pos.y;
        }
        avgX /= heat.creatures.size();
        avgY /= heat.creatures.size();
        int radius = (int) map(heat.creatures.size(), 0, hottest, 0, 400);
        for (int r = radius; r > 0; r-=20) {
          fill(335, 100, 100, map(r, 0, radius, 100, 0));
          ellipse(avgX, avgY, r, r);
        }
      }
    }
  }

  private class CreatureStore {
    ArrayList<Creature> creatures = new ArrayList();
  }
}
