String toLowerCamelCase(String text) {
  // Convert text to lower camel case
  final words = text.split('_').map((word) => word.toLowerCase()).toList();
  words[0] = '${words[0][0].toLowerCase()}${words[0].substring(1)}';

  for (int i = 1; i < words.length; i++) {
    words[i] = '${words[i][0].toUpperCase()}${words[i].substring(1)}';
  }

  return words.join('');
}
