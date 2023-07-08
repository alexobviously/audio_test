import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:audio_test/utils.dart';
import 'package:wav/wav.dart';

final _parser = ArgParser()
  ..addOption('in', abbr: 'i')
  ..addOption('out', abbr: 'o')
  ..addOption('speed', abbr: 's', defaultsTo: '1.0')
  ..addOption('winsize', abbr: 'w', defaultsTo: '100', help: 'in ms')
  ..addOption('winoverlap', abbr: 'v', defaultsTo: '2')
  ..addOption(
    'winamp', // lol
    abbr: 'a',
    defaultsTo: '0.1',
  );

void main(List<String> argss) async {
  final args = _parser.parse(argss);
  final wav = await Wav.readFile(args['in']);
  final double speed = double.parse(args['speed']);
  final double winSizeSec = int.parse(args['winsize']) / 1000;
  final int winLength = int.parse(args['winoverlap']);
  final double winAmp = double.parse(args['winamp']);
  final audio = wav.toMono();
  final int sr = wav.samplesPerSecond;
  final int wSize = (sr * winSizeSec).floor();
  final int numWindows = audio.length ~/ wSize;
  final double modifier = 1 / speed;
  final wSize2 = (wSize * modifier).round();
  print('numwins $numWindows');

  List<List<double>> windows = List.generate(
    numWindows,
    (i) => windowSegment(
      // take 2 windows for overlap
      audio.sublist(i * wSize, min((i + winLength) * wSize, audio.length)),
      winAmp,
    ),
  );

  List<double> out = List.generate((audio.length * modifier).floor(), (_) => 0);
  for (int i = 0; i < numWindows; i++) {
    final int start = (i * wSize2).floor();
    // final int end = min((i + 1) * wSize2, out.length);
    for (int j = 0; j < windows[i].length; j++) {
      if (start + j >= out.length) break;
      out[start + j] += windows[i][j];
    }
  }

  final outWav = Wav([Float64List.fromList(out)], sr);
  outWav.writeFile(args['out']);
}
