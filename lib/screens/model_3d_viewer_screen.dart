import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/logo_widget.dart';

class Model3DViewerScreen extends StatefulWidget {
  const Model3DViewerScreen({super.key});

  @override
  State<Model3DViewerScreen> createState() => _Model3DViewerScreenState();
}

class _Model3DViewerScreenState extends State<Model3DViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedModel = 'IM0004.glb';
  
  final Map<String, String> _models = {
    'IM0004.glb': 'Maintenance of Closed Loop Systems',
    'IM6930.glb': 'PLC Fundamentals',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _loadModel(_selectedModel);
  }

  void _loadModel(String modelName) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Try to load from GitHub raw URL first, fallback to local asset path
    // Replace with your actual GitHub username and repo
    final githubRawUrl = 'https://raw.githubusercontent.com/hadefuwa/matrix-android-app/main/assets/$modelName';
    
    // Alternative: If hosting elsewhere, use that URL instead
    // final modelUrl = 'https://your-server.com/assets/$modelName';
    
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
            overflow: hidden;
            font-family: Arial, sans-serif;
        }
        #model-container {
            width: 100vw;
            height: 100vh;
            position: relative;
        }
        model-viewer {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #0A0A0F 0%, #1A1A2E 100%);
        }
        /* Hide AR button */
        model-viewer::part(default-ar-button) {
            display: none !important;
        }
        /* Hide any AR-related buttons */
        button[slot="ar-button"],
        .ar-button {
            display: none !important;
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
        .error {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #ff6b6b;
            text-align: center;
            padding: 20px;
            background: rgba(26, 26, 46, 0.9);
            border-radius: 12px;
            border: 2px solid #9C27B0;
            z-index: 10;
            max-width: 90%;
        }
        .error h3 {
            margin-bottom: 10px;
        }
        .error p {
            margin: 8px 0;
            line-height: 1.5;
        }
    </style>
    <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js"></script>
</head>
<body>
    <div id="model-container">
        <div class="loading">Loading 3D Model: $modelName...</div>
        <model-viewer
            id="model-viewer"
            src="$githubRawUrl"
            alt="3D Model"
            environment-image="neutral"
            auto-rotate
            camera-controls
            interaction-policy="allow-when-focused"
            shadow-intensity="1"
            exposure="1"
            style="width: 100%; height: 100%;">
            <div slot="poster" style="color: #E0B0FF; text-align: center; padding: 20px;">
                <p>Loading 3D Model: $modelName...</p>
            </div>
        </model-viewer>
    </div>
    <script>
        const viewer = document.getElementById('model-viewer');
        const loading = document.querySelector('.loading');
        let loadTimeout;
        let errorShown = false;
        const modelName = '$modelName';
        
        // Set a timeout for loading (30 seconds)
        loadTimeout = setTimeout(() => {
            if (loading && !errorShown) {
                loading.style.display = 'none';
                errorShown = true;
                const errorDiv = document.createElement('div');
                errorDiv.className = 'error';
                errorDiv.innerHTML = '<h3>Loading Timeout</h3><p>The model is taking too long to load. This might be due to:<br>• Large file size<br>• Slow internet connection<br>• File may be corrupted</p><p style="font-size: 12px; margin-top: 10px;">Model: ' + modelName + '</p>';
                document.body.appendChild(errorDiv);
            }
        }, 30000);
        
        viewer.addEventListener('load', () => {
            clearTimeout(loadTimeout);
            if (loading) loading.style.display = 'none';
            
            // Remove AR button if it exists
            const arButton = viewer.shadowRoot?.querySelector('button[slot="ar-button"]');
            if (arButton) {
                arButton.style.display = 'none';
            }
            
            // Remove any AR-related elements
            const arElements = viewer.shadowRoot?.querySelectorAll('[slot="ar-button"], .ar-button, button[aria-label*="AR"], button[aria-label*="ar"]');
            if (arElements) {
                arElements.forEach(el => el.style.display = 'none');
            }
        });
        
        viewer.addEventListener('error', (e) => {
            clearTimeout(loadTimeout);
            if (loading && !errorShown) {
                loading.style.display = 'none';
                errorShown = true;
                const errorDiv = document.createElement('div');
                errorDiv.className = 'error';
                const errorDetails = e.detail ? String(e.detail) : 'Unknown error';
                errorDiv.innerHTML = '<h3>Error Loading Model</h3><p>Failed to load: ' + modelName + '</p><p style="font-size: 12px; color: #999;">Error: ' + errorDetails + '</p><p style="margin-top: 10px;">Possible causes:<br>• File not found on server<br>• Corrupted GLB file<br>• Network error<br>• File format issue</p>';
                document.body.appendChild(errorDiv);
            }
        });
        
        // Also listen for model-viewer specific errors
        viewer.addEventListener('model-error', (e) => {
            clearTimeout(loadTimeout);
            if (loading && !errorShown) {
                loading.style.display = 'none';
                errorShown = true;
                const errorDiv = document.createElement('div');
                errorDiv.className = 'error';
                errorDiv.innerHTML = '<h3>Model Format Error</h3><p>The GLB file may be corrupted or invalid.</p><p style="font-size: 12px; margin-top: 10px;">Model: ' + modelName + '</p>';
                document.body.appendChild(errorDiv);
            }
        });
        
        // Periodically check and remove AR button (in case it appears after load)
        setInterval(() => {
            const arButton = viewer.shadowRoot?.querySelector('button[slot="ar-button"]');
            if (arButton) {
                arButton.style.display = 'none';
                arButton.remove();
            }
        }, 500);
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
                  : 'Failed to load 3D model';
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  void _changeModel(String modelName) {
    if (_selectedModel != modelName) {
      setState(() {
        _selectedModel = modelName;
      });
      _loadModel(modelName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(width: 28, height: 28),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  purple,
                  purple.withValues(alpha: 0.7),
                  const Color(0xFFE0B0FF),
                ],
              ).createShader(bounds),
              child: Text(
                _models[_selectedModel] ?? '3D Model Viewer',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F1E),
        foregroundColor: const Color(0xFFE0B0FF),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.model_training, color: purple),
            tooltip: 'Select Model',
            onSelected: _changeModel,
            itemBuilder: (context) => _models.entries.map((entry) {
              return PopupMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      _selectedModel == entry.key 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      color: purple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontWeight: _selectedModel == entry.key 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: purple),
            onPressed: () {
              _loadModel(_selectedModel);
            },
            tooltip: 'Refresh',
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
              // WebView with 3D model
              WebViewWidget(controller: _controller),
              // Loading indicator overlay
              if (_isLoading && _errorMessage == null)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(purple),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading ${_models[_selectedModel]}...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Error message overlay
              if (_errorMessage != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Center(
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
                            'Error loading model',
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
                              _loadModel(_selectedModel);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Note: Make sure the GLB files are pushed to GitHub\nand accessible via raw file URLs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

