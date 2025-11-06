import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EASMViewerScreen extends StatefulWidget {
  final String? easmFilePath; // Path to local EASM file
  final String? easmUrl; // URL to hosted EASM file
  
  const EASMViewerScreen({
    super.key,
    this.easmFilePath,
    this.easmUrl,
  });

  @override
  State<EASMViewerScreen> createState() => _EASMViewerScreenState();
}

class _EASMViewerScreenState extends State<EASMViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Option 1: Try using an online EASM viewer or converter service
    // Note: EASM files typically require eDrawings software
    // This is a placeholder that attempts to use a web-based solution
    
    const htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        body {
            margin: 0;
            padding: 20px;
            background-color: #0A0A0F;
            color: white;
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            max-width: 600px;
        }
        .info-box {
            background-color: #1A1A2E;
            padding: 20px;
            border-radius: 12px;
            margin: 20px 0;
            border: 2px solid #9C27B0;
        }
        .info-box h2 {
            color: #E0B0FF;
            margin-top: 0;
        }
        .info-box p {
            color: #CCCCCC;
            line-height: 1.6;
        }
        .button {
            background: linear-gradient(135deg, #9C27B0, #E0B0FF);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            margin: 10px;
            text-decoration: none;
            display: inline-block;
        }
        .button:hover {
            opacity: 0.9;
        }
        .model-viewer-container {
            width: 100%;
            height: 500px;
            background-color: #1A1A2E;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 20px 0;
        }
        model-viewer {
            width: 100%;
            height: 100%;
            background-color: #0A0A0F;
        }
    </style>
    <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js"></script>
</head>
<body>
    <div class="container">
        <div class="info-box">
            <h2>📦 EASM File Viewer</h2>
            <p><strong>Note:</strong> EASM files are proprietary eDrawings format files. To view them in this app, you have a few options:</p>
        </div>
        
        <div class="info-box">
            <h3>Option 1: Convert to GLTF/OBJ/STL</h3>
            <p>Convert your EASM file to a standard 3D format (GLTF recommended) using SOLIDWORKS or other CAD software, then upload it here.</p>
            <p>Once converted, you can use the 3D viewer below:</p>
            
            <div class="model-viewer-container">
                <model-viewer
                    src=""
                    alt="3D Model"
                    ar
                    ar-modes="webxr scene-viewer quick-look"
                    environment-image="neutral"
                    auto-rotate
                    camera-controls
                    style="width: 100%; height: 100%;">
                    <div slot="poster" style="color: white; text-align: center; padding: 20px;">
                        <p>No 3D model loaded</p>
                        <p style="font-size: 12px; color: #999;">Upload a GLTF/GLB file to view</p>
                    </div>
                </model-viewer>
            </div>
            
            <p style="font-size: 14px; color: #999; margin-top: 10px;">
                To use: Replace the empty src="" above with your GLTF file URL
            </p>
        </div>
        
        <div class="info-box">
            <h3>Option 2: Use eDrawings Mobile App</h3>
            <p>For native EASM support, users can download the free eDrawings mobile app from the Play Store or App Store.</p>
            <p style="font-size: 14px; color: #999;">
                The app can open .easm, .eprt, and .edrw files directly.
            </p>
        </div>
        
        <div class="info-box">
            <h3>Option 3: Host and Link</h3>
            <p>Host your EASM file online and provide a download link. Users can download and open it with eDrawings app.</p>
        </div>
    </div>
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
                  : 'Failed to load viewer';
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
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              purple,
              purple.withValues(alpha: 0.7),
              const Color(0xFFE0B0FF),
            ],
          ).createShader(bounds),
          child: const Text(
            '3D Model Viewer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF0F0F1E),
        foregroundColor: const Color(0xFFE0B0FF),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: purple),
            onPressed: () {
              _controller.reload();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: purple),
            onSelected: (value) {
              if (value == 'info') {
                _showInfoDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Viewing Options'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          child: Stack(
            children: [
              // WebView
              WebViewWidget(controller: _controller),
              // Loading indicator
              if (_isLoading && _errorMessage == null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(purple),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading viewer...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              // Error message
              if (_errorMessage != null)
                Center(
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
                          'Error loading viewer',
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
                            _controller.reload();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'EASM File Viewing Options',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(
                'Option 1: Convert to GLTF',
                'Convert your EASM file to GLTF format using SOLIDWORKS or online converters. GLTF files can be viewed directly in the web viewer.',
                Icons.transform,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Option 2: eDrawings App',
                'Users can download the free eDrawings mobile app to view EASM files natively.',
                Icons.phone_android,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Option 3: Host Online',
                'Host your EASM file online and provide a download link for users.',
                Icons.cloud_upload,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String description, IconData icon) {
    final purple = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: purple, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

