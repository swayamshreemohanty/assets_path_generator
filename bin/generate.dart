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
    ..addOption('source-dir', abbr: 'S', help: 'Source directory that contains the image assets.', callback: (String? value) => validateNotEmpty(value, 'source-dir'))
    ..addOption('output-file', abbr: 'O', help: 'Output file where the generated Dart code will be saved.', callback: (String? value) => validateNotEmpty(value, 'output-file'))
    ..addOption('class-name', abbr: 'C', help: 'Class name for the generated Dart code.', callback: (String? value) => validateNotEmpty(value, 'class-name'));

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
  final buffer = StringBuffer()..writeln('abstract class $className {');
  String lastDirName = '';

  // Iterate through the source directory and process each entity
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity.path.split('/').last.startsWith('.')) return; // Skip hidden files and directories

    if (entity is Directory) {
      lastDirName = processDirectory(entity, sourceDir, buffer, lastDirName);
    } else if (entity is File) {
      lastDirName = processFile(entity, sourceDir, buffer, lastDirName);
    }
  });

  buffer.writeln('}');
  return buffer;
}

String processDirectory(Directory entity, Directory sourceDir, StringBuffer buffer, String lastDirName) {
  final dirPath = getRelativePath(entity, sourceDir);
  final dirName = dirPath.split('/').last;
  final camelCaseDirName = _toLowerCamelCase(dirName);

  // Write directory path as a constant
  buffer.writeln('\n  // $dirName');
  buffer.writeln('  static const String _${camelCaseDirName}Path = "${sourceDir.path.replaceAll('\\', '/')}/$dirPath";');

  return dirName;
}

String processFile(File entity, Directory sourceDir, StringBuffer buffer, String lastDirName) {
  final filePath = getRelativePath(entity, sourceDir);
  final fileNameWithExtension = filePath.split('/').last;
  final fileName = fileNameWithExtension.split('.').first;
  final fileExtension = fileNameWithExtension.split('.').last;
  final dirName = filePath.split('/').reversed.toList()[1];

  // Write file path as a constant
  if (dirName != lastDirName) {
    buffer.writeln('\n  // $dirName');
  }

  final camelCaseDirName = _toLowerCamelCase(dirName);
  final lowerCamelCaseFileName = _toLowerCamelCase(fileName);

  buffer.writeln('  static const String $lowerCamelCaseFileName = "\$_${camelCaseDirName}Path/$fileName.$fileExtension";');

  return dirName;
}

String getRelativePath(FileSystemEntity entity, Directory sourceDir) {
  // Get the relative path of the entity from the source directory
  return entity.path.replaceAll('\\', '/').replaceFirst(sourceDir.path.replaceAll('\\', '/') + '/', '');
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

  final targetParentFolderName = path.basename(sourceDir.path);
  // Remove existing asset paths related to the source directory
  lines.removeWhere((line) => line.trim().startsWith('- assets/$targetParentFolderName') || line.trim() == '    - assets/');

  // Ensure there is an "assets/" entry
  if (!lines.contains('    - assets/')) {
    lines.insert(assetIndex + 1, '    - assets/');
  }

  final newPaths = <String>{};
  // Collect new asset paths
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity is Directory) {
      final relativePath = path.relative(entity.path, from: Directory.current.path).replaceAll('\\', '/');
      newPaths.add(relativePath + '/');
    }
  });

  // Sort and add new asset paths to pubspec.yaml
  final sortedPaths = newPaths.toList()..sort();
  for (final newPath in sortedPaths) {
    lines.insert(assetIndex + 2, '    - $newPath');
  }

  // Write the updated pubspec.yaml file
  pubspecFile.writeAsStringSync(lines.join('\n'));
  print('pubspec.yaml updated successfully!');
}
