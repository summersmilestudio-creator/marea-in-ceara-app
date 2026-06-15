import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MareaInCearaApp());
}

class MareaInCearaApp extends StatelessWidget {
  const MareaInCearaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marea în Ceară',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4A574)),
        useMaterial3: true,
      ),
      home: const ShopWebView(),
    );
  }
}

class ShopWebView extends StatefulWidget {
  const ShopWebView({super.key});

  @override
  State<ShopWebView> createState() => _ShopWebViewState();
}

class _ShopWebViewState extends State<ShopWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  // Privacy (App Store guideline 5.1.2(i)): the app never tracks the user. The
  // website detects the app's User-Agent ("MareaInCeara") and, in-app, loads no
  // analytics and shows no cookie-consent banner (see cookie-consent.js). As an
  // extra safety net we also neutralise Google Analytics + the Facebook Pixel
  // here in case any third-party script ever slips in. We deliberately set NO
  // cookie from the app, so the app itself collects nothing.
  static const String _noTrackingJs =
      "try{"
      "window['ga-disable-G-JNM8P1M0DJ']=true;"
      "window.gtag=function(){};window.dataLayer=[];"
      "window.fbq=function(){};window._fbq=function(){};"
      "var b=document.getElementById('cookieBanner');"
      "if(b&&b.parentNode){b.parentNode.removeChild(b);}"
      "}catch(e){}";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _controller.runJavaScript(_noTrackingJs);
            setState(() {
              _isLoading = true;
            });
          },
          onProgress: (progress) {
            _controller.runJavaScript(_noTrackingJs);
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (url) {
            _controller.runJavaScript(_noTrackingJs);
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _showError(error.description);
            }
          },
        ),
      )
      ..setUserAgent('MareaInCeara/1.0 Android')
      ..loadRequest(Uri.parse('https://mareainceara.ro/'));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eroare: $message'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Reîncarcă',
          textColor: Colors.white,
          onPressed: () => _controller.reload(),
        ),
      ),
    );
  }

  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          _controller.goBack();
        } else {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Apasă din nou pentru a ieși'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4A574),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
