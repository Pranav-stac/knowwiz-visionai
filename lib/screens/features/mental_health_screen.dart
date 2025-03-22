import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MentalHealthScreen extends StatelessWidget {
  const MentalHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://useful-herring-radically.ngrok-free.app',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            webViewController.loadUrl('https://useful-herring-radically.ngrok-free.app');
          },
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('https://useful-herring-radically.ngrok-free.app')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      ),
    );
  }
}
