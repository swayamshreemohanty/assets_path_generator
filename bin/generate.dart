import 'dart:io';

import 'package:assets_path_generator/generate_dart_code.dart';
import 'package:assets_path_generator/parse_arguments.dart';
import 'package:assets_path_generator/update_pubspec_file.dart';
import 'package:assets_path_generator/utils/validate_source_directory.dart';

void main(List<String> args) {
  try {
    // Parse command line arguments
    final argResults = parseArguments(args);
    final sourceDir = Directory(argResults['source-dir']);
    final destinationFile = File(argResults['output-file']);
    final className = argResults['class-name'];

    // Validate the source directory
    validateSourceDirectory(sourceDir);

    // Generate Dart code from the source directory
    final buffer = generateDartCode(sourceDir, className);

    // Write the generated Dart code to the output file
    destinationFile.writeAsStringSync(buffer.toString());

    // Update the pubspec.yaml file with new asset paths
    updatePubspecFile(sourceDir);
  } catch (e) {
    // Print any errors that occur
    print("Error: $e");
  }
}
