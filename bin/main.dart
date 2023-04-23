import 'dart:typed_data';
import 'package:audio_test/audio_test.dart';
import 'package:wav/wav.dart';

const sampleRate = 48000;

void main() async {
  // List<double> sinWave = List.generate(
  //   sampleRate,
  //   (i) => sin(((pi * 2) / (sampleRate / 440)) * i) * 0.5,
  // );
  // final wav = Wav([Float64List.fromList(sinWave)], sampleRate);
  // wav.writeFile('test.wav');

  final sine = SineGen(Val(440) + (SineGen(Val(0.2)) * Val(40)));
  // final sine = SineGen(Val(440) + Val(40));
  final gen = Amplifier(sine, SineGen(Val(1)).abs());
  // gen.stream.listen(();
  List<double> floats = [];
  gen.stream.listen((e) => floats.addAll(e.$2));
  gen.getBlock(6000);
  await Future.delayed(Duration(seconds: 1));
  final wav = Wav([Float64List.fromList(floats)], sampleRate);
  wav.writeFile('test.wav');
}
