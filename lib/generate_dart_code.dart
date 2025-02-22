import 'dart:io';

import 'package:assets_path_generator/utils/process_directory.dart';
import 'package:assets_path_generator/utils/process_file.dart';

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
