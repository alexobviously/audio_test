import 'package:fftea/fftea.dart';

List<double> resample(List<double> input, double rate) => List.generate(
    (input.length * rate).round(),
    (i) => input[(i / rate).round() % input.length]);

List<double> pad(
  List<double> input,
  int length, {
  bool truncate = true,
}) =>
    [
      ...(truncate ? input.take(length) : input),
      if (input.length < length) ...List.filled(length - input.length, 0.0),
    ];

List<double> truncate(List<double> input, int length) =>
    input.take(length).toList();

List<double> windowSegment(List<double> input, [double amp = 0.1]) {
  final window = Window.cosine(input.length, amp);
  return window.applyWindowReal(input);
}
