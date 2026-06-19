import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ReaderErrorCallback = void Function(String message);

class ReaderWebViewConfig {
  const ReaderWebViewConfig({
    required this.initialUri,
    required this.userAgent,
    required this.onProgress,
    required this.onLoadError,
  });

  final Uri initialUri;
  final String userAgent;
  final ValueChanged<int> onProgress;
  final ReaderErrorCallback onLoadError;
}

class ReaderWebView extends StatefulWidget {
  const ReaderWebView({required this.config, super.key});

  final ReaderWebViewConfig config;

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setUserAgent(widget.config.userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: widget.config.onProgress,
          onWebResourceError: (error) {
            widget.config.onLoadError(error.description);
          },
          onNavigationRequest: (request) {
            final requestedUri = Uri.tryParse(request.url);
            if (requestedUri == null) {
              return NavigationDecision.prevent;
            }
            if (requestedUri.host == widget.config.initialUri.host) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.config.initialUri);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
