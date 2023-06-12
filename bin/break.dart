// A rudimentary breakbeat generator.
// Run this with `--help` to see the options.

import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:audio_test/audio_test.dart';
import 'package:fftea/stft.dart';
import 'package:wav/wav.dart';

typedef Segment = (int, List<double>);
typedef ComposeFunction = List<Segment> Function(
  List<Segment> segments,
  int length,
);

enum Composer {
  random(composeRandom),
  walk(composeWalking);

  final ComposeFunction compose;
  const Composer(this.compose);
}

final _parser = ArgParser()
  ..addOption(
    'bpm',
    abbr: 'b',
    defaultsTo: '135',
    help: 'BPM of the input file.',
  )
  ..addOption(
    'in',
    abbr: 'i',
    defaultsTo: 'amen_135.wav',
    help: 'The source audio file to cut up.',
  )
  ..addOption(
    'out',
    abbr: 'o',
    defaultsTo: 'break.wav',
    help: 'The name of the file to write to.',
  )
  ..addOption(
    'length',
    abbr: 'l',
    defaultsTo: '64',
    help: 'The desired output length in beats.',
  )
  ..addFlag('help', abbr: 'h')
  ..addOption(
    'composer',
    abbr: 'c',
    allowed: ['random', 'walk'],
    defaultsTo: 'walk',
    help: 'The algorithm used to compose the output.',
  )
  ..addOption(
    'reverses',
    abbr: 'r',
    defaultsTo: '4',
    help: 'Creates this number of reversed segments. '
        'Only works with \'random\' composer.',
  );

void main(List<String> args) async {
  final parsedArgs = _parser.parse(args);
  if (parsedArgs['help']) {
    print(_parser.usage);
    return;
  }

  final int bpm = int.parse(parsedArgs['bpm']);
  final int numReverses = int.parse(parsedArgs['reverses']);
  final wav = await Wav.readFile(parsedArgs['in']);
  final int sr = wav.samplesPerSecond;
  final audio = wav.toMono();
  final samples = audio.length;
  final composer =
      Composer.values.firstWhere((e) => e.name == parsedArgs['composer']);
  final int outLengthBeats = int.parse(parsedArgs['length']);

  int beat = samplesPerBeat(bpm, sr);
  int numBeats = (samples / beat).round();
  print('sr: $sr, samples: $samples, per beat: $beat, beats: $numBeats');
  print('duration: ${(samples / sr * 1000).toStringAsFixed(2)}ms');

  List<Segment> segments = List.generate(
    numBeats,
    (i) =>
        (i, windowSegment(pad(audio.skip(i * beat).take(beat).toList(), beat))),
  );

  // Creates a few reversed segments, only works with the 'random' composer.
  if (numReverses > 0) {
    List<Segment> revSegments = randomIndices(segments.length, numReverses)
        .map((i) => (-i - 1, segments[i].$2.reversed.toList()))
        .toList(); // reversed for ordering
    segments.addAll(revSegments);
  }

  final outSegments = composer.compose(segments, outLengthBeats);
  print('Composed: ${outSegments.map((e) => e.$1).toList()}');

  final buffer = outSegments.expand((e) => e.$2).toList();
  print('Output buffer length: ${buffer.length}');
  final windowed = Window.cosine(buffer.length, 0.15).applyWindowReal(buffer);
  final out = Wav([Float64List.fromList(windowed)], sr);

  out.writeFile(parsedArgs['out']);
}

List<Segment> composeRandom(List<Segment> segments, int length) =>
    List.generate(length, (i) => segments[Random().nextInt(segments.length)]);

List<Segment> composeWalking(
  List<Segment> segments,
  int length, {
  bool includeReversed = false,
}) {
  if (!includeReversed) {
    segments.removeWhere((e) => e.$1 < 0);
  }
  int index = 0;
  // 20% stay, 35% back 1 beat, 35% forward 1 beat, 10% forward 1 bar
  int nextIndex() => switch (Random().nextInt(100)) {
        < 35 => (index - 1) % segments.length,
        > 90 => (index + 4) % segments.length,
        > 55 => (index + 1) % segments.length,
        _ => index,
      };
  return List.generate(length, (_) {
    final seg = segments[index];
    index = nextIndex();
    return seg;
  });
}

List<double> windowSegment(List<double> input) {
  final window = Window.cosine(input.length, 0.1);
  return window.applyWindowReal(input);
}

Iterable<int> randomIndices(int length, int count) =>
    (List.generate(length, (i) => i)..shuffle()).take(count);
