import 'package:audio_test/audio_test.dart';
import 'package:rxdart/subjects.dart';

abstract class ValueSource {
  const ValueSource();
  double getValue(int blockIndex, [int sampleIndex = 0]);
  List<double> getBlock(int index);

  Abs abs() => Abs(this);
  AddProcessor operator +(ValueSource other) => AddProcessor(this, other);
  Amplifier operator *(ValueSource other) => Amplifier(this, other);
}

abstract class BlockSource extends ValueSource {
  @override
  List<double> getBlock(int index);
  @override
  double getValue(int blockIndex, [int sampleIndex = 0]) =>
      getBlock(blockIndex)[sampleIndex];
  const BlockSource();
}

class StaticBlockSource extends BlockSource {
  final List<double> block;
  const StaticBlockSource(this.block);

  @override
  List<double> getBlock(int index) => block;
}

class StaticValue extends ValueSource {
  final double value;
  const StaticValue(this.value);

  @override
  double getValue(int blockIndex, [int sampleIndex = 0]) => value;

  @override
  List<double> getBlock(int index) => List.filled(blockSize, value);
}

// inline class?
class Val extends StaticValue {
  const Val(super.value);
}

abstract class StreamBlockSource extends BlockSource {
  int _blockIndex = 0;
  int get blockIndex => _blockIndex;
  List<double> get _currentBlock => _subject.value.$2;

  final BehaviorSubject<(int, List<double>)> _subject = BehaviorSubject();
  Stream<(int, List<double>)> get stream => _subject.stream;

  void _emit(List<double> block) {
    _subject.add((_blockIndex, block));
    _blockIndex++;
  }

  List<double> generateBlock();

  @override
  double getValue(int blockIndex, [int sampleIndex = 0]) =>
      getBlock(blockIndex).first;

  @override
  List<double> getBlock(int index) {
    while (index >= _blockIndex) {
      _emit(generateBlock());
    }
    return _currentBlock;
  }
}
