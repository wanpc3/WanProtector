class NormalizeUrl {

  static String urlFormatter(String rawUrl) {
    String url = rawUrl;

    //Remove leading slash if exists
    url = url.replaceFirst(RegExp(r'^/+'), '');

    url = url.replaceFirstMapped(
    RegExp(r'^(https?):/?([^/])'),
      (match) => '${match[1]}://${match[2]}',
    );

    if (!url.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      url = 'https://$url';
    }

    return url;
  }

}