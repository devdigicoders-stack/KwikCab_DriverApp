import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;

  const PaymentWebviewScreen({
    Key? key,
    required this.paymentUrl,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
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

            // Check if the URL contains our return callback
            if (request.url.contains('success=true')) {
              Navigator.of(context).pop(true); // Return true for success
              return NavigationDecision.prevent;
            } else if (request.url.contains('error=')) {
              Navigator.of(context).pop(false); // Return false for failure
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
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text(
          'Online Payment',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
          ],
        ),
      ),
    );
  }
}
