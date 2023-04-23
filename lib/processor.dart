import 'package:audio_test/audio_test.dart';

abstract class Processor extends StreamBlockSource {
  final ValueSource parent;
  Processor(this.parent);

  List<double> processBlock(List<double> block);

  @override
  List<double> generateBlock() => processBlock(parent.getBlock(blockIndex));
}

class Amplifier extends Processor {
  final ValueSource gain;
  Amplifier(super.parent, this.gain);

  @override
  List<double> processBlock(List<double> block) {
    double gain = this.gain.getValue(blockIndex);
    return block.map((e) => e * gain).toList();
  }
}

class Abs extends Processor {
  Abs(super.parent);

  @override
  List<double> processBlock(List<double> block) =>
      block.map((e) => e.abs()).toList();
}

class AddProcessor extends Processor {
  final ValueSource other;
  AddProcessor(super.parent, this.other);
  factory AddProcessor.value(ValueSource parent, double value) =>
      AddProcessor(parent, Val(value));

  @override
  List<double> processBlock(List<double> block) {
    List<double> additive = other.getBlock(blockIndex);
    return List.generate(blockSize, (i) => block[i] + additive[i]);
  }
}

class MultiplyProcessor extends Processor {
  final ValueSource other;
  MultiplyProcessor(super.parent, this.other);
  factory MultiplyProcessor.value(ValueSource parent, double value) =>
      MultiplyProcessor(parent, Val(value));

  @override
  List<double> processBlock(List<double> block) {
    List<double> additive = other.getBlock(blockIndex);
    return List.generate(blockSize, (i) => block[i] * additive[i]);
  }
}
