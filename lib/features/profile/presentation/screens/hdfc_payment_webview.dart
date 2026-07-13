import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class HdfcPaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  const HdfcPaymentWebviewScreen({super.key, required this.paymentUrl});

  @override
  State<HdfcPaymentWebviewScreen> createState() => _HdfcPaymentWebviewScreenState();
}

class _HdfcPaymentWebviewScreenState extends State<HdfcPaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            
            // Allow UPI and other intent schemes to open native apps
            if (url.startsWith('upi://') || 
                url.startsWith('gpay://') || 
                url.startsWith('phonepe://') || 
                url.startsWith('paytmmp://') ||
                url.startsWith('intent://') ||
                url.startsWith('tez://')) {
              _launchIntent(url);
              return NavigationDecision.prevent;
            }

            // Intercept Success Redirect from backend
            if (url.contains('success=true')) {
              Navigator.pop(context, true); // return success
              return NavigationDecision.prevent;
            } 
            // Intercept Failure/Error Redirect
            else if (url.contains('error=')) {
              Navigator.pop(context, false); // return failure
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _launchIntent(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $urlString");
      }
    } catch (e) {
      debugPrint("Error launching intent: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('HDFC Payment Gateway', style: TextStyle(color: AppColors.white, fontSize: 16)),
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // If user closes manually, return false (cancelled)
            Navigator.pop(context, false);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            ),
        ],
      ),
    );
  }
}
