import 'dart:io';

import 'package:assets_path_generator/utils/get_relative_path.dart';
import 'package:assets_path_generator/utils/to_lower_camel_case.dart';

String processDirectory(Directory entity, Directory sourceDir,
    StringBuffer buffer, String lastDirName) {
  final dirPath = getRelativePath(entity, sourceDir);
  final dirName = dirPath.split('/').last;
  final camelCaseDirName = toLowerCamelCase(dirName);

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
