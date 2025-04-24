import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void updatePubspecFile(Directory sourceDir) {
  final pubspecFile = File('pubspec.yaml');

  // Check if pubspec.yaml exists
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    return;
  }

  print('Reading pubspec.yaml...');
  final pubspecContent = pubspecFile.readAsStringSync();
  final yamlEditor = YamlEditor(pubspecContent);

  // Parse the YAML content
  final yamlMap = loadYaml(pubspecContent) as Map;

  // Check if the "flutter" and "assets" sections exist
  if (!yamlMap.containsKey('flutter') ||
      !(yamlMap['flutter'] as Map).containsKey('assets')) {
    print('Error: "flutter" or "assets" section not found in pubspec.yaml');
    return;
  }

  final assetsList = (yamlMap['flutter']['assets'] as List).cast<String>();

  // Get the relative path of the source directory
  final sourcePath = path
      .relative(sourceDir.path, from: Directory.current.path)
      .replaceAll('\\', '/');

  // Filter out existing paths under the source directory
  final updatedAssets =
      assetsList.where((asset) => !asset.startsWith('$sourcePath/')).toList();

  // Collect new asset paths from the source directory
  final newPaths = <String>{};
  sourceDir.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity is Directory) {
      final relativePath = path
          .relative(entity.path, from: Directory.current.path)
          .replaceAll('\\', '/');
      newPaths.add('$relativePath/');
    }
  });

  // Sort and add new asset paths under the source directory
  final sortedPaths = newPaths.toList()..sort();
  updatedAssets.addAll(sortedPaths);

  // Update the "assets" section in the YAML
  yamlEditor.update(['flutter', 'assets'], updatedAssets);

  // Write the updated pubspec.yaml file
  pubspecFile.writeAsStringSync(yamlEditor.toString());
  print('pubspec.yaml updated successfully!');
}
