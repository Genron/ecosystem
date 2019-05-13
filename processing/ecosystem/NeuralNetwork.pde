class NeuralNetwork {
  int inputNodes, hiddenNodes, outputNodes;
  Matrix weightsIh, weightsHo, biasH, biasO;
  float learningRate;
  String savePath;
  int iterations;

  NeuralNetwork(int inputNodes, int hiddenNodes, int outputNodes) {
    this.inputNodes = inputNodes;
    this.hiddenNodes = hiddenNodes;
    this.outputNodes = outputNodes;

    this.weightsIh = new Matrix(this.hiddenNodes, this.inputNodes);
    this.weightsIh.randomize();
    this.weightsHo = new Matrix(this.outputNodes, this.hiddenNodes);
    this.weightsHo.randomize();

    this.biasH = new Matrix(this.hiddenNodes, 1);
    this.biasH.randomize();
    this.biasO = new Matrix(this.outputNodes, 1);
    this.biasO.randomize();

    this.learningRate = .1;
    this.iterations = 0;
  }

  NeuralNetwork(int inputNodes, int hiddenNodes, int outputNodes, float learningRate) {
    this(inputNodes, hiddenNodes, outputNodes);
    this.learningRate = learningRate;
  }

  NeuralNetwork(String path) {
    // Loads network from file
    String[] lines = loadStrings(path);

    // Store the savePath, line 0
    this.savePath = lines[0].split(";")[0];

    // Set learning rate, line 1
    this.learningRate = Float.parseFloat(lines[1].split(";")[0]);

    // Load node values, line 2
    String[] nodes = lines[2].split(";")[0].split(", ");
    this.inputNodes = Integer.parseInt(nodes[0]);
    this.hiddenNodes = Integer.parseInt(nodes[1]);
    this.outputNodes = Integer.parseInt(nodes[2]);

    // Restore input -> hidden matrix, line 3
    this.weightsIh = new Matrix(this.hiddenNodes, this.inputNodes);
    String[] wih = lines[3].split(";")[0].split(",");
    for (int y=0; y<this.hiddenNodes; ++y) {
      for (int x=0; x<this.inputNodes; ++x) {
        this.weightsIh.set(y, x, Float.parseFloat(wih[y*this.inputNodes + x]));
      }
    }

    // Restore hidden -> output matrix, line 4
    this.weightsHo = new Matrix(this.outputNodes, this.hiddenNodes);
    String[] who = lines[4].split(";")[0].split(",");
    for (int y=0; y<this.outputNodes; ++y) {
      for (int x=0; x<this.hiddenNodes; ++x) {
        this.weightsHo.set(y, x, Float.parseFloat(who[y*this.hiddenNodes + x]));
      }
    }

    // Restore bias hidden matrix, line 5
    this.biasH = new Matrix(this.hiddenNodes, 1);
    String[] bh = lines[5].split(";")[0].split(",");
    for (int y=0; y<this.hiddenNodes; ++y) {
      this.biasH.set(y, 0, Float.parseFloat(bh[y]));
    }

    // Restore bias output matrix, line 6
    this.biasO = new Matrix(this.outputNodes, 1);
    String[] bo = lines[6].split(";")[0].split(",");
    for (int y=0; y<this.outputNodes; ++y) {
      this.biasO.set(y, 0, Float.parseFloat(bo[y]));
    }

    // Load iteration count, line 7
    this.iterations = Integer.parseInt(lines[7].split(";")[0]);

    // Shows the loaded neural network
    println("Neural network successfully loaded");
    //show();
  }

  void show() {
    println("learningRate: " + learningRate);
    println("iterations: " + iterations);
    println("inputNodes: " + inputNodes);
    println("hiddenNodes: " + hiddenNodes);
    println("outputNodes: " + outputNodes);
    weightsIh.show(); 
    weightsHo.show(); 
    biasH.show(); 
    biasO.show();
    println("------");
  }

  String randomSeq(int len) {
    return len > 0 ? String.valueOf(floor(random(10))) + randomSeq(len - 1) : "";
  }

  void save() {
    if (null == savePath) {
      savePath = "neuralNetwork" + randomSeq(6) + ".txt";
    }
    println("Saving neural network to... " + savePath);

    // Create a new file in the sketch directory
    PrintWriter output = createWriter(savePath);
    output.println(savePath + "; // savePath (String)");
      output.println(learningRate + "; // learningRate (float)");
      output.println(inputNodes + ", " + hiddenNodes + ", " + outputNodes + "; // input-, hidden & outputNodes (int)");

      float[] ihout = weightsIh.toArray();
    for (int i=0; i<ihout.length; ++i) {
      output.print(ihout[i] + (i!=ihout.length-1 ? ", " : "; "));
    }
    output.println("// weightsIh (Matrix)");

      float[] hoout = weightsHo.toArray();
    for (int i=0; i<hoout.length; ++i) {
      output.print(hoout[i] + (i!=hoout.length-1 ? ", " : "; "));
    }
    output.println("// weightsHo (Matrix)");

      float[] bhout = biasH.toArray();
    for (int i=0; i<bhout.length; ++i) {
      output.print(bhout[i] + (i!=bhout.length-1 ? ", " : "; "));
    }
    output.println("// biasH (Matrix)");

      float[] boout = biasO.toArray();
    for (int i=0; i<boout.length; ++i) {
      output.print(boout[i] + (i!=boout.length-1 ? ", " : "; "));
    }
    output.println("// biasO (Matrix)");

      output.println(iterations + "; // iterations (String)");

      output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
  }

  void save(String path) {
    savePath = path;
    save();
  }

  // feed forward
  float[] predict(float[] input) {
    // Convert from array to Matrix
    Matrix inputs = toMatrix(input);

    // Generating the hidden outputs
    Matrix hidden = weightsIh.copy();

    hidden.mult(inputs);
    hidden.add(biasH);

    // Activation function
    hidden.sign();

    // Generating the output
    Matrix output = weightsHo.copy();
    output.mult(hidden);
    output.add(biasO);
    output.sign();

    // Return an array instead of a matrix
    return output.toArray();
  }

  void train(float[] input, float[] targets) {

    if (input.length != inputNodes) {
      println("Input size does not match");
      return;
    }
    if (targets.length != outputNodes) {
      println("Output size does not match");
      return;
    }

    // Convert from array to Matrix
    Matrix inputs = toMatrix(input);

    // Generating the hidden outputs
    Matrix hidden = weightsIh.copy();

    hidden.mult(inputs);
    hidden.add(biasH);

    // Activation function
    hidden.sign();

    // Generating the output
    Matrix output = weightsHo.copy();
    output.mult(hidden);
    output.add(biasO);
    output.sign();

    // Adjust errors -------------------------------------------
    //Matrix outputs = toMatrix(feedForward(input));
    Matrix outputs = output.copy();
    Matrix outputErrors = toMatrix(targets);

    // Calculate outputErrors ------------------
    outputErrors.sub(outputs);

    // Calculate gradient
    Matrix gradients = outputs.copy();
    gradients.dSign();

    gradients.multElem(outputErrors);
    gradients.mult(learningRate); // learningRate

    // Calculate deltas
    Matrix hiddenT = hidden.copy();
    hiddenT.transp();
    Matrix weightHoDeltas = gradients.copy();
    weightHoDeltas.mult(hiddenT);

    // Adjust weights
    this.weightsHo.add(weightHoDeltas);
    biasO.add(gradients);

    // Calculate the hidden layer errors ----------------
    Matrix hiddenErrors = weightsHo.copy();
    hiddenErrors.transp();
    hiddenErrors.mult(outputErrors);

    // Calculate hidden gradient
    Matrix hiddenGradient = hidden.copy();
    hiddenGradient.dSign();
    hiddenGradient.multElem(hiddenErrors);
    hiddenGradient.mult(learningRate); // learningRate

    // Calculate input -> hidden deltas
    Matrix inputsT = inputs.copy();
    inputsT.transp();
    Matrix weightIhDeltas = hiddenGradient.copy();
    weightIhDeltas.mult(inputsT);

    // Adjust weights
    this.weightsIh.add(weightIhDeltas);
    biasH.add(hiddenGradient);
  }

  Matrix toMatrix(float[] input) {
    Matrix inputs = new Matrix(input.length, 1);
    for (int i=0; i<input.length; ++i) {
      inputs.set(i, 0, input[i]);
    }
    return inputs;
  }

  NeuralNetwork copy() {
    NeuralNetwork clone = new NeuralNetwork(inputNodes, hiddenNodes, outputNodes, learningRate);
    clone.savePath = this.savePath;
    clone.iterations = this.iterations;

    clone.weightsIh = this.weightsIh.copy();
    clone.weightsHo = this.weightsHo.copy();
    clone.biasH = this.biasH.copy();
    clone.biasO = this.biasO.copy();

    return clone;
  }

  void mutate(float probability, float range) {
    // weightsIh, weightsHo, biasH, biasO;
    weightsIh.mutate(probability, range);
    weightsHo.mutate(probability, range);
    biasH.mutate(probability, range);
    biasO.mutate(probability, range);
  }
}
