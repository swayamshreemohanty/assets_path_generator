import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) {
  try {
    final argResults = parseArguments(args);
    final sourceDir = Directory(argResults['source-dir']);
    final destinationFile = File(argResults['output-file']);
    final className = argResults['class-name'];
    validateSourceDirectory(sourceDir);
    final buffer = generateDartCode(sourceDir, className);
    destinationFile.writeAsStringSync(buffer.toString());
    updatePubspecFile(sourceDir);
  } catch (e) {
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

  return parser.parse(args);
}

void validateNotEmpty(String? value, String key) {
  if (value == null || value.isEmpty) {
    throw ArgumentError('$key cannot be null or empty.');
  }
}

void validateSourceDirectory(Directory sourceDir) {
  if (!sourceDir.existsSync()) {
    print('Error: Source directory does not exist.');
    exit(1);
  }
}

StringBuffer generateDartCode(Directory sourceDir, String className) {
  final buffer = StringBuffer()..writeln('abstract class $className {');
  String lastDirName = '';
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    // Skip hidden files and directories
    if (entity.path.split('/').last.startsWith('.')) {
      return;
    }

    // Process directories and files
    if (entity is Directory) {
      lastDirName = processDirectory(entity, sourceDir, buffer, lastDirName);
    } else if (entity is File) {
      lastDirName = processFile(entity, sourceDir, buffer, lastDirName);
    }
  });

  buffer.writeln('}');
  return buffer;
}

String processDirectory(
  Directory entity,
  Directory sourceDir,
  StringBuffer buffer,
  String lastDirName,
) {
  final dirPath = getRelativePath(entity, sourceDir);
  final dirName = dirPath.split('/').last;
  final camelCaseDirName = _toLowerCamelCase(dirName);
  buffer.writeln('\n  // $dirName');
  buffer.writeln(
      '  static const String _${camelCaseDirName}Path = "${sourceDir.path.replaceAll('\\', '/')}/$dirPath";');
  return dirName;
}

String processFile(
  File entity,
  Directory sourceDir,
  StringBuffer buffer,
  String lastDirName,
) {
  final filePath = getRelativePath(entity, sourceDir);
  final fileNameWithExtension = filePath.split('/').last;
  final fileName = fileNameWithExtension.split('.').first;
  final fileExtension = fileNameWithExtension.split('.').last;
  final dirName = filePath.split('/').reversed.toList()[1];
  if (dirName != lastDirName) {
    buffer.writeln('\n  // $dirName');
  }
  final camelCaseDirName = _toLowerCamelCase(dirName);
  final lowerCamelCaseFileName = _toLowerCamelCase(fileName);
  buffer.writeln(
    '  static const String $lowerCamelCaseFileName = "\$_${camelCaseDirName}Path/$fileName.$fileExtension";',
  );
  return dirName;
}

String getRelativePath(FileSystemEntity entity, Directory sourceDir) {
  return entity.path
      .replaceAll('\\', '/')
      .replaceFirst(sourceDir.path.replaceAll('\\', '/') + '/', '');
}

String _toLowerCamelCase(String text) {
  final words = text.split('_').map((word) => word.toLowerCase()).toList();
  words[0] = '${words[0][0].toLowerCase()}${words[0].substring(1)}';
  for (int i = 1; i < words.length; i++) {
    words[i] = '${words[i][0].toUpperCase()}${words[i].substring(1)}';
  }
  return words.join('');
}

void updatePubspecFile(Directory sourceDir) {
  final pubspecFile = File('pubspec.yaml');
  final lines = pubspecFile.readAsLinesSync();
  int assetIndex = lines.indexWhere((line) => line.trim() == 'assets:');
  if (assetIndex == -1) {
    print('Error: "assets:" section not found in pubspec.yaml');
    return;
  }

  // Remove existing asset paths that start with the target parent folder name
  String targetParentFolderName = path.basename(sourceDir.path);
  lines.removeWhere(
      (line) => line.trim().startsWith('- assets/$targetParentFolderName'));

  // Update the assetIndex
  assetIndex = lines.indexWhere((line) => line.trim() == 'assets:');

  // Add default asset path if it doesn't exist
  if (!lines.contains('    - assets/')) {
    lines.insert(assetIndex + 1, '    - assets/');
  }

  // Add new asset paths
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity is Directory) {
      final relativePath =
          entity.path.substring(sourceDir.path.length).replaceAll('\\', '/');
      lines.insert(
          assetIndex + 2, '    - assets/$targetParentFolderName$relativePath/');
    }
  });

  pubspecFile.writeAsStringSync(lines.join('\n'));
}
