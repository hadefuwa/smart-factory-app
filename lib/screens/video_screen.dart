import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/logo_widget.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _videoBase64;

  @override
  void initState() {
    super.initState();
    _loadVideoAsset();
  }

  Future<void> _loadVideoAsset() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load video file as bytes
      final ByteData data = await rootBundle.load(
        'assets/Industrial Maintenance - IM0004 Maintenance of closed loop systems Overview.mp4',
      );
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Convert to base64 for embedding in HTML
      final String base64Video = base64Encode(bytes);
      final String videoDataUri = 'data:video/mp4;base64,$base64Video';

      setState(() {
        _videoBase64 = videoDataUri;
      });

      _initializeWebView();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video file: $e\n\nPlease ensure the video file exists in the assets folder.';
      });
    }
  }

  void _initializeWebView() {
    if (_videoBase64 == null) return;

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #0A0A0F 0%, #1A1A2E 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            overflow: hidden;
        }
        .video-container {
            width: 100%;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        video {
            width: 100%;
            height: auto;
            max-height: 100vh;
            outline: none;
        }
        .loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #E0B0FF;
            font-size: 18px;
            text-align: center;
            z-index: 10;
        }
        .loading::after {
            content: '';
            display: block;
            width: 40px;
            height: 40px;
            margin: 20px auto;
            border: 3px solid #9C27B0;
            border-top-color: transparent;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="video-container">
        <div class="loading">Loading video...</div>
        <video id="video-player" controls autoplay>
            <source src="$_videoBase64" type="video/mp4">
            Your browser does not support the video tag.
        </video>
    </div>
    <script>
        const video = document.getElementById('video-player');
        const loading = document.querySelector('.loading');
        
        video.addEventListener('loadeddata', () => {
            if (loading) loading.style.display = 'none';
        });
        
        video.addEventListener('error', (e) => {
            if (loading) loading.style.display = 'none';
            const errorDiv = document.createElement('div');
            errorDiv.style.cssText = 'position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #ff6b6b; text-align: center; padding: 20px; background: rgba(26, 26, 46, 0.9); border-radius: 12px;';
            errorDiv.innerHTML = '<h3>Error Loading Video</h3><p>Failed to load video file.</p>';
            document.body.appendChild(errorDiv);
        });
    </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description.isNotEmpty
                  ? error.description
                  : 'Failed to load video';
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(width: 28, height: 28),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  purple,
                  purple.withValues(alpha: 0.7),
                  const Color(0xFFE0B0FF),
                ],
              ).createShader(bounds),
              child: const Text(
                'Smart Factory Video',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F1E),
        foregroundColor: const Color(0xFFE0B0FF),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                purple.withValues(alpha: 0.15),
                Colors.transparent,
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: _errorMessage != null
              ? _buildErrorWidget(context)
              : (_isLoading
                  ? _buildLoadingWidget(context, purple)
                  : WebViewWidget(controller: _controller)),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context, Color purple) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(purple),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _loadVideoAsset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
