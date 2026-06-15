import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// App Tracking Transparency (App Store guideline 5.1.2(i)).
///
/// The shop website (mareainceara.ro) loaded in the WebView uses cookies that
/// may be used to track users (Google Analytics / Facebook Pixel). Apple
/// requires us to ask the user's permission through the ATT framework *before*
/// any tracking data is collected — i.e. before the WebView loads the site.
///
/// We request once, after the first frame is on screen so the app is in the
/// foreground when the system prompt appears (otherwise the prompt silently
/// never shows). The returned status decides whether the site's tracking
/// scripts are allowed to run (see main.dart).
class TrackingService {
  TrackingService._();

  /// Returns true if the user authorized tracking. On non-iOS platforms there
  /// is no ATT, so we report `false` and keep tracking disabled in-app.
  static Future<bool> requestIfNeeded() async {
    if (!Platform.isIOS) return false;
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Give the UI a moment to settle so the prompt reliably shows.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      return status == TrackingStatus.authorized;
    } catch (_) {
      // Never let ATT block app startup; default to "no tracking".
      return false;
    }
  }
}
