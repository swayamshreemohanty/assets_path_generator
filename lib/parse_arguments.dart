import 'package:args/args.dart';

ArgResults parseArguments(List<String> args) {
  final parser = ArgParser()
    ..addOption('source-dir',
        abbr: 'S',
        help: 'Source directory that contains the image assets.',
        callback: (String? value) => validateNotEmpty(value, 'source-dir'))
    ..addOption('output-file',
        abbr: 'O',
        help: 'Output file where the generated Dart code will be saved.',
        callback: (String? value) => validateNotEmpty(value, 'output-file'))
    ..addOption('class-name',
        abbr: 'C',
        help: 'Class name for the generated Dart code.',
        callback: (String? value) => validateNotEmpty(value, 'class-name'));

  // Parse and return the command line arguments
  return parser.parse(args);
}



void validateNotEmpty(String? value, String key) {
  // Ensure that the provided value is not null or empty
  if (value == null || value.isEmpty) {
    throw ArgumentError('$key cannot be null or empty.');
  }
}