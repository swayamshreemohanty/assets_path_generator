import 'dart:io';

String getRelativePath(FileSystemEntity entity, Directory sourceDir) {
  // Get the relative path of the entity from the source directory
  return entity.path
      .replaceAll('\\', '/')
      .replaceFirst(sourceDir.path.replaceAll('\\', '/') + '/', '');
}

