import 'dart:math';
import 'dart:typed_data';

import 'package:audio_test/audio_test.dart';

class SineGen extends StreamBlockSource {
  final ValueSource frequency;

  SineGen(this.frequency);

  @override
  List<double> generateBlock() {
    num samplesPerCycle = sampleRate / frequency.getValue(blockIndex);
    num stepSize = (pi * 2) / samplesPerCycle;
    // num stepSize =
    List<int> phases =
        List.generate(blockSize, (i) => blockIndex * blockSize + i);
    List<double> block = phases.map((e) => sin(stepSize * e)).toList();
    return Float64List.fromList(block);
  }
}
