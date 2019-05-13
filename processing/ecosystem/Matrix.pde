class Matrix {
  int rows, cols;
  float[][] values;

  // Constructors --------------------------------------
  Matrix(float[]... values) {
    this.rows = values.length;
    this.cols = values[0].length;
    this.values = new float[rows][cols];    
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        this.values[y][x] = values[y][x];
      }
    }
  }

  Matrix(int rows, int cols) {
    this.rows = rows;
    this.cols = cols;
    this.values = new float[rows][cols];    
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        values[y][x] = 0;
      }
    }
  }

  Matrix() {
    this(2, 3);
  }

  // Operations ---------------------------------------
  float get(int y, int x) {
    return values[y][x];
  }

  void set(int y, int x, float value) {
    values[y][x] = value;
  }

  void add(float n) {
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        values[y][x] += n;
      }
    }
  }

  void add(Matrix m) {
    if (this.rows == m.rows && this.cols == m.cols) {
      for (int y=0; y<rows; y++) {
        for (int x=0; x<cols; x++) {
          values[y][x] += m.get(y, x);
        }
      }
    } else {
      println("matricies are not equal");
    }
  }

  void sub(Matrix m) {
    if (this.rows == m.rows && this.cols == m.cols) {
      for (int y=0; y<rows; y++) {
        for (int x=0; x<cols; x++) {
          values[y][x] -= m.get(y, x);
        }
      }
    } else {
      println("matricies are not equal-sub");
    }
  }

  void mult(float n) {
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        values[y][x] *= n;
      }
    }
  }

  // hadamard
  void multElem(Matrix m) {
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        values[y][x] *= m.get(y, x);
      }
    }
  }

  void mult(Matrix m) {
    if (this.cols == m.rows) {
      Matrix mProd = new Matrix(this.rows, m.cols);
      for (int y=0; y<mProd.rows; y++) {
        for (int x=0; x<mProd.cols; x++) {
          float val = 0;
          for (int i=0; i<this.cols; ++i) {
            val += this.get(y, i) * m.get(i, x);
          }
          mProd.set(y, x, val);
        }
      }
      this.rows = mProd.rows;
      this.cols = mProd.cols;
      this.values = mProd.values;
    } else {
      println("rows and cols are not equal: this.rows=" + this.rows + ", m.cols=" + m.cols);
    }
  }

  void transp() {
    Matrix mTransp = new Matrix(this.cols, this.rows);
    for (int y=0; y<this.rows; y++) {
      for (int x=0; x<this.cols; x++) {
        float val = get(y, x);
        mTransp.set(x, y, val);
      }
    }
    this.rows = mTransp.rows;
    this.cols = mTransp.cols;
    this.values = mTransp.values;
  }

  // creates a deep copy of this matrix
  Matrix copy() {
    return new Matrix(values);
  }

  void randomize() {
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        values[y][x] = (float) Math.random() * 2 - 1; // Value between -1 & 1
      }
    }
  }

  void mutate(float probability, float range) {
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        float random = random(1) < probability ? random(-range, range) : 0;
        values[y][x] += random; // Value between -1 & 1
      }
    }
  }

  float[] toArray() {
    float[] result = new float[cols*rows];
    for (int y=0; y<rows; y++) {
      for (int x=0; x<cols; x++) {
        result[y*cols+x] = values[y][x];
      }
    }
    return result;
  }

  void sign() {
    for (int y=0; y<this.rows; y++) {
      for (int x=0; x<this.cols; x++) {
        values[y][x] = sigmoid(values[y][x]);
      }
    }
  }

  void dSign() {
    for (int y=0; y<this.rows; y++) {
      for (int x=0; x<this.cols; x++) {
        //float sig = sigmoid(values[y][x]);
        //values[y][x] = sig * (1 - sig);
        float sig = values[y][x];
        values[y][x] = sig * (1 - sig);
      }
    }
  }

  float sigmoid(float x) {
    return 1 / (1 + (float) Math.exp(-x));
  }

  void show() {
    for (int y=0; y<rows; y++) {
      String val = "[";
      for (int x=0; x<cols; x++) {
        val += values[y][x] + ", ";
      }
      println(val.substring(0, val.length()-2) + "]");
    }
    println("---");
  }
}
