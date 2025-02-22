import 'dart:io';

void validateSourceDirectory(Directory sourceDir) {
  // Check if the source directory exists
  if (!sourceDir.existsSync()) {
    print('Error: Source directory does not exist.');
    exit(1);
  }
}
