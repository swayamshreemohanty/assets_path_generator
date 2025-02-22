import 'dart:io';

import 'package:path/path.dart' as path;

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
