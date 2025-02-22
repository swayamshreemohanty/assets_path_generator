import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

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

void validateSourceDirectory(Directory sourceDir) {
  // Check if the source directory exists
  if (!sourceDir.existsSync()) {
    print('Error: Source directory does not exist.');
    exit(1);
  }
}

StringBuffer generateDartCode(Directory sourceDir, String className) {
  final buffer = StringBuffer()
    ..writeln('// ignore_for_file: public_member_api_docs')
    ..writeln('abstract class $className {');
  String lastDirName = '';

  // Iterate through the source directory and process each entity
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity.path.split('/').last.startsWith('.'))
      return; // Skip hidden files and directories

    if (entity is Directory) {
      lastDirName = processDirectory(entity, sourceDir, buffer, lastDirName);
    } else if (entity is File) {
      lastDirName = processFile(entity, sourceDir, buffer, lastDirName);
    }
  });

  buffer.writeln('}');
  return buffer;
}

String processDirectory(Directory entity, Directory sourceDir,
    StringBuffer buffer, String lastDirName) {
  final dirPath = getRelativePath(entity, sourceDir);
  final dirName = dirPath.split('/').last;
  final camelCaseDirName = _toLowerCamelCase(dirName);

  // Check if the directory contains any files
  final hasFiles = entity
      .listSync(recursive: false, followLinks: false)
      .any((e) => e is File);

  if (hasFiles) {
    // Write directory path as a constant
    buffer.writeln('\n  // $dirName');
    buffer.writeln(
        '  static const String _${camelCaseDirName}Path = "${sourceDir.path.replaceAll('\\', '/')}/$dirPath";');
  }

  return hasFiles ? dirName : lastDirName;
}

String processFile(
    File entity, Directory sourceDir, StringBuffer buffer, String lastDirName) {
  final filePath = getRelativePath(entity, sourceDir);
  final fileNameWithExtension = filePath.split('/').last;
  final fileName = fileNameWithExtension.split('.').first;
  final fileExtension = fileNameWithExtension.split('.').last;
  final pathSegments = filePath.split('/');

  // Handle files directly under the source directory
  final dirName = pathSegments.length > 1 ? pathSegments[pathSegments.length - 2] : '';

  // Write directory path as a constant if it's different from the last directory
  if (dirName != lastDirName && dirName.isNotEmpty) {
    final camelCaseDirName = _toLowerCamelCase(dirName);
    buffer.writeln('\n  // $dirName');
    buffer.writeln(
        '  static const String _${camelCaseDirName}Path = "${sourceDir.path.replaceAll('\\', '/')}/$dirName";');
  } else if (dirName.isEmpty) {
    // Handle files directly under the source directory
    final sourceDirName = sourceDir.path.split('/').last;
    buffer.writeln('\n  // $sourceDirName');
    buffer.writeln(
        '  static const String _${_toLowerCamelCase(sourceDirName)}Path = "${sourceDir.path.replaceAll('\\', '/')}";');
  }

  final camelCaseDirName = dirName.isNotEmpty ? _toLowerCamelCase(dirName) : _toLowerCamelCase(sourceDir.path.split('/').last);
  final lowerCamelCaseFileName = _toLowerCamelCase(fileName);

  buffer.writeln(
      '  static const String $lowerCamelCaseFileName = "\$_${camelCaseDirName}Path/$fileName.$fileExtension";');

  return dirName;
}
String getRelativePath(FileSystemEntity entity, Directory sourceDir) {
  // Get the relative path of the entity from the source directory
  return entity.path
      .replaceAll('\\', '/')
      .replaceFirst(sourceDir.path.replaceAll('\\', '/') + '/', '');
}

String _toLowerCamelCase(String text) {
  // Convert text to lower camel case
  final words = text.split('_').map((word) => word.toLowerCase()).toList();
  words[0] = '${words[0][0].toLowerCase()}${words[0].substring(1)}';

  for (int i = 1; i < words.length; i++) {
    words[i] = '${words[i][0].toUpperCase()}${words[i].substring(1)}';
  }

  return words.join('');
}

void updatePubspecFile(Directory sourceDir) {
  final pubspecFile = File('pubspec.yaml');

  // Check if pubspec.yaml exists
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    return;
  }

  print('Reading pubspec.yaml...');
  final lines = pubspecFile.readAsLinesSync();

  // Find the index of the "assets:" section
  int assetIndex = lines.indexWhere((line) => line.trim() == 'assets:');
  if (assetIndex == -1) {
    print('Error: "assets:" section not found in pubspec.yaml');
    return;
  }

  print('Found "assets:" section in pubspec.yaml.');

  // Remove all existing paths under the "assets:" section
  int nextSectionIndex = lines.length;
  for (int i = assetIndex + 1; i < lines.length; i++) {
    if (!lines[i].trim().startsWith('- assets/')) {
      nextSectionIndex = i;
      break;
    }
  }
  lines.removeRange(assetIndex + 1, nextSectionIndex);

  final newPaths = <String>{};

  // Collect new asset paths
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity is Directory) {
      final relativePath = path
          .relative(entity.path, from: Directory.current.path)
          .replaceAll('\\', '/');
      final newPath = '    - $relativePath/';
      newPaths.add(newPath);
    } else if (entity is File) {
      final relativePath = path
          .relative(entity.parent.path, from: Directory.current.path)
          .replaceAll('\\', '/');
      final newPath = '    - $relativePath/';
      newPaths.add(newPath);
    }
  });

  // Sort and add new asset paths to pubspec.yaml
  final sortedPaths = newPaths.toList()..sort();
  for (final newPath in sortedPaths) {
    lines.insert(assetIndex + 1, newPath);
  }

  // Write the updated pubspec.yaml file
  pubspecFile.writeAsStringSync(lines.join('\n'));
  print('pubspec.yaml updated successfully!');
}