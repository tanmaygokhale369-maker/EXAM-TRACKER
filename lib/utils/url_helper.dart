import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in the browser.
/// On web: opens in new tab.
/// On Android/iOS: opens in external browser.
Future<void> openUrl(String url) async {
  if (url.isEmpty) return;
  
  // Ensure URL has scheme
  String finalUrl = url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    finalUrl = 'https://$url';
  }

  final uri = Uri.parse(finalUrl);
  
  if (kIsWeb) {
    // On web, use url_launcher which opens in new tab
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // On mobile
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}