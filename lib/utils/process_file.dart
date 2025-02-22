import 'dart:io';

import 'package:assets_path_generator/utils/get_relative_path.dart';
import 'package:assets_path_generator/utils/to_lower_camel_case.dart';

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
  final pathSegments = filePath.split('/');

  // Handle files directly under the source directory
  final dirName =
      pathSegments.length > 1 ? pathSegments[pathSegments.length - 2] : '';

  // Write directory path as a constant if it's different from the last directory
  if (dirName != lastDirName && dirName.isNotEmpty) {
    final camelCaseDirName = toLowerCamelCase(dirName);
    buffer.writeln('\n  // $dirName');
    buffer.writeln(
        '  static const String _${camelCaseDirName}Path = "${sourceDir.path.replaceAll('\\', '/')}/$dirName";');
  } else if (dirName.isEmpty) {
    // Handle files directly under the source directory
    final sourceDirName = sourceDir.path.split('/').last;
    buffer.writeln('\n  // $sourceDirName');
    buffer.writeln(
        '  static const String _${toLowerCamelCase(sourceDirName)}Path = "${sourceDir.path.replaceAll('\\', '/')}";');
  }

  final camelCaseDirName = dirName.isNotEmpty
      ? toLowerCamelCase(dirName)
      : toLowerCamelCase(sourceDir.path.split('/').last);
  final lowerCamelCaseFileName = toLowerCamelCase(fileName);

  buffer.writeln(
      '  static const String $lowerCamelCaseFileName = "\$_${camelCaseDirName}Path/$fileName.$fileExtension";');

  return dirName;
}
