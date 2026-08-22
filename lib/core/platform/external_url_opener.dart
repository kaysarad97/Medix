import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlOpener = Future<bool> Function(Uri uri);

/// Opens short-lived storage links outside the application.
///
/// Kept behind a provider so screens do not depend directly on a platform
/// channel and the complete download flow can be covered by widget tests.
final externalUrlOpenerProvider = Provider<ExternalUrlOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
