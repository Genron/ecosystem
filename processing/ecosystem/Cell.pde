class Cell {
  float x, y, size;
  float value, baseValue;
  float h, s, b;
  static final float plantGrowthRate = .001;

  Cell(float x, float y, float size, float value, float h, float s, float b) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.value = value;
    baseValue = value;
    this.h = h;
    this.s = s;
    this.b = b;
  }

  void display() {
    textAlign(CENTER, CENTER);
    noStroke();
    float ms = map(value, 0, baseValue, s*.8, s);
    float mb = map(value, 0, baseValue, b*.8, b);
    fill(h, ms, mb);
    rect(x*size, y*size, size, size);
    fill(map(b, 0, 100, 255, 0));
    text(floor(value*10), x*size+size/2, y*size+size/2);
    
  }

  void update() {
    float diff = value - baseValue; // 11-9=2
    float decrease = diff * plantGrowthRate; // 2*.01=.002
    value -= decrease; // 11-.002=10.998
  }

  // removes the value of the field by either the amount of consumation value which is passed over or the actual value which is left on the cell and returns also this value.
  float consumeFood(float consumptionRate) {

    // to make food unattractive: return only partial value. eg. 0.9=90% of desired food.
    // except there is more food at the cell than the maximum potential, then get the desired amount of food.
    // => motivation for creatures to move to fields with potential 1
    //                   0.8 <= 0.9          0.9 * 0.2 => 0.18
    //                   1.2 <= 0.9                                      0.2 => 0.2
    float consume = value <= baseValue ? baseValue * consumptionRate : consumptionRate;
    consume = min(consume, value); // get either the consume value (we ask for) or the actual value (which is available)
    value -= consume;
    return consume;
  }
}
