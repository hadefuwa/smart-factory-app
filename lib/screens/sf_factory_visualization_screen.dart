import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../widgets/app_drawer.dart';

class SFFactoryVisualizationScreen extends StatefulWidget {
  const SFFactoryVisualizationScreen({super.key});

  @override
  State<SFFactoryVisualizationScreen> createState() => _SFFactoryVisualizationScreenState();
}

class _SFFactoryVisualizationScreenState extends State<SFFactoryVisualizationScreen>
    with TickerProviderStateMixin {
  final SimulatorService _simulator = SimulatorService();
  late AnimationController _conveyorAnimationController;
  late AnimationController _pulseAnimationController;
  bool _showSensorZones = true;
  bool _showComponentStatus = true;
  bool _showPartLabels = false;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _conveyorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _conveyorAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _showARInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.view_in_ar, color: Colors.purple),
            SizedBox(width: 8),
            Text('AR Mode'),
          ],
        ),
        content: const Text(
          'AR (Augmented Reality) mode is coming soon!\n\n'
          'This feature will allow you to view the factory visualization overlaid on your physical environment using your device camera.\n\n'
          'AR support requires additional packages and will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Factory Visualization'),
        actions: [
          // Toggle sensor zones
          IconButton(
            icon: Icon(
              _showSensorZones ? Icons.visibility : Icons.visibility_off,
              color: _showSensorZones ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showSensorZones = !_showSensorZones;
              });
            },
            tooltip: 'Toggle Sensor Zones',
          ),
          // Toggle component status
          IconButton(
            icon: Icon(
              _showComponentStatus ? Icons.info : Icons.info_outline,
              color: _showComponentStatus ? purple : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showComponentStatus = !_showComponentStatus;
              });
            },
            tooltip: 'Toggle Component Status',
          ),
          // Toggle part labels
          IconButton(
            icon: Icon(
              _showPartLabels ? Icons.label : Icons.label_outline,
            ),
            onPressed: () {
              setState(() {
                _showPartLabels = !_showPartLabels;
              });
            },
            tooltip: 'Toggle Part Labels',
          ),
          // AR mode (placeholder)
          IconButton(
            icon: const Icon(Icons.view_in_ar),
            onPressed: () {
              _showARInfo(context);
            },
            tooltip: 'AR Mode (Coming Soon)',
          ),
        ],
      ),
      body: StreamBuilder<SimulatorState>(
        stream: Stream.periodic(
          const Duration(milliseconds: 50),
          (_) => _simulator.currentState,
        ),
        initialData: _simulator.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data!;
          final parts = _simulator.getParts();

          return GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 3.0);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _panOffset += details.delta;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    purple.withValues(alpha: 0.1),
                    Colors.transparent,
                    const Color(0xFF0A0A0F),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Factory visualization
                  Center(
                    child: Transform.scale(
                      scale: _zoomLevel,
                      child: Transform.translate(
                        offset: _panOffset,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _FactoryPainter(
                            state: state,
                            parts: parts,
                            showSensorZones: _showSensorZones,
                            showComponentStatus: _showComponentStatus,
                            showPartLabels: _showPartLabels,
                            conveyorAnimation: _conveyorAnimationController,
                            pulseAnimation: _pulseAnimationController,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Controls overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _ControlsOverlay(
                      state: state,
                      zoomLevel: _zoomLevel,
                      onZoomIn: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
                        });
                      },
                      onZoomOut: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
                        });
                      },
                      onReset: () {
                        setState(() {
                          _zoomLevel = 1.0;
                          _panOffset = Offset.zero;
                        });
                      },
                    ),
                  ),
                  // Legend
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _VisualizationLegend(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FactoryPainter extends CustomPainter {
  final SimulatorState state;
  final List<PartInfo> parts;
  final bool showSensorZones;
  final bool showComponentStatus;
  final bool showPartLabels;
  final Animation<double> conveyorAnimation;
  final Animation<double> pulseAnimation;

  _FactoryPainter({
    required this.state,
    required this.parts,
    required this.showSensorZones,
    required this.showComponentStatus,
    required this.showPartLabels,
    required this.conveyorAnimation,
    required this.pulseAnimation,
  }) : super(repaint: Listenable.merge([conveyorAnimation, pulseAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final conveyorWidth = size.width * 0.8;
    final conveyorHeight = 40.0;
    final startX = size.width * 0.1;
    final conveyorY = centerY;

    // Draw background grid
    _drawGrid(canvas, size);

    // Draw conveyor belt base
    _drawConveyorBelt(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);

    // Draw sensor zones
    if (showSensorZones) {
      _drawSensorZones(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);
    }

    // Draw sensors
    _drawSensors(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);

    // Draw parts on conveyor
    _drawParts(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);

    // Draw actuators (paddles, plunger, vacuum)
    _drawActuators(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);

    // Draw component status overlays
    if (showComponentStatus) {
      _drawComponentStatus(canvas, startX, conveyorY, conveyorWidth, conveyorHeight);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawConveyorBelt(Canvas canvas, double startX, double y, double width, double height) {
    // Conveyor base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, y - height / 2, width, height),
      const Radius.circular(8),
    );
    final basePaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(baseRect, basePaint);

    // Conveyor belt animation (moving stripes)
    if (state.conveyor && state.isRunning) {
      final stripePaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final stripeWidth = 20.0;
      final offset = (conveyorAnimation.value * stripeWidth * 2) % (stripeWidth * 2);
      
      for (double x = startX - offset; x < startX + width; x += stripeWidth * 2) {
        canvas.drawRect(
          Rect.fromLTWH(x, y - height / 2, stripeWidth, height),
          stripePaint,
        );
      }
    }

    // Conveyor border
    final borderPaint = Paint()
      ..color = state.conveyor ? Colors.green : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(baseRect, borderPaint);
  }

  void _drawSensorZones(Canvas canvas, double startX, double y, double width, double height) {
    final zonePaint = Paint()
      ..style = PaintingStyle.fill;

    // First Gate zone (20% of conveyor)
    zonePaint.color = Colors.blue.withValues(alpha: state.firstGate ? 0.3 : 0.1);
    canvas.drawRect(
      Rect.fromLTWH(startX + width * 0.2, y - height / 2 - 30, width * 0.05, height + 60),
      zonePaint,
    );

    // Inductive/Capacitive zone (40% of conveyor)
    zonePaint.color = Colors.orange.withValues(alpha: (state.inductive || state.capacitive) ? 0.3 : 0.1);
    canvas.drawRect(
      Rect.fromLTWH(startX + width * 0.4, y - height / 2 - 30, width * 0.05, height + 60),
      zonePaint,
    );

    // Photo Gate zone (90% of conveyor)
    zonePaint.color = Colors.purple.withValues(alpha: state.photoGate ? 0.3 : 0.1);
    canvas.drawRect(
      Rect.fromLTWH(startX + width * 0.9, y - height / 2 - 30, width * 0.05, height + 60),
      zonePaint,
    );
  }

  void _drawSensors(Canvas canvas, double startX, double y, double width, double height) {
    // First Gate sensor
    _drawSensor(
      canvas,
      startX + width * 0.2,
      y - height / 2 - 20,
      'First Gate',
      state.firstGate,
      Colors.blue,
    );

    // Inductive sensor
    _drawSensor(
      canvas,
      startX + width * 0.4,
      y - height / 2 - 20,
      'Inductive',
      state.inductive,
      Colors.orange,
    );

    // Capacitive sensor (slightly offset)
    _drawSensor(
      canvas,
      startX + width * 0.4,
      y + height / 2 + 20,
      'Capacitive',
      state.capacitive,
      Colors.orange,
    );

    // Photo Gate sensor
    _drawSensor(
      canvas,
      startX + width * 0.9,
      y - height / 2 - 20,
      'Photo Gate',
      state.photoGate,
      Colors.purple,
    );
  }

  void _drawSensor(Canvas canvas, double x, double y, String label, bool active, Color color) {
    final sensorPaint = Paint()
      ..color = active ? color : Colors.grey
      ..style = PaintingStyle.fill;

    // Sensor body
    canvas.drawCircle(Offset(x, y), 12, sensorPaint);

    // Active indicator (pulsing)
    if (active) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.3 * pulseAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 12 + (pulseAnimation.value * 8), pulsePaint);
    }

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 30));
  }

  void _drawParts(Canvas canvas, double startX, double y, double width, double height) {
    for (final part in parts) {
      final partX = startX + (part.position * width);
      if (partX < startX || partX > startX + width) continue;

      final partColor = _getPartColor(part.material);
      final partPaint = Paint()
        ..color = partColor
        ..style = PaintingStyle.fill;

      // Draw part as circle
      canvas.drawCircle(Offset(partX, y), 12, partPaint);

      // Part border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(partX, y), 12, borderPaint);

      // Material indicator
      final materialPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(partX, y), 6, materialPaint);

      // Label if enabled
      if (showPartLabels) {
        final label = _getMaterialLabel(part.material);
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(partX - textPainter.width / 2, y + 18));
      }

      // Trail effect for moving parts
      if (state.conveyor && state.isRunning) {
        final trailPaint = Paint()
          ..color = partColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(partX - 15, y), 8, trailPaint);
        canvas.drawCircle(Offset(partX - 30, y), 4, trailPaint);
      }
    }
  }

  void _drawActuators(Canvas canvas, double startX, double y, double width, double height) {
    // Steel paddle
    if (state.paddleSteel) {
      _drawPaddle(canvas, startX + width * 0.4, y - height / 2 - 15, true, Colors.grey);
    }

    // Aluminium paddle
    if (state.paddleAluminium) {
      _drawPaddle(canvas, startX + width * 0.4, y + height / 2 + 15, false, Colors.lightBlue);
    }

    // Plunger
    if (state.plungerDown) {
      _drawPlunger(canvas, startX + width * 0.6, y, true);
    }

    // Vacuum
    if (state.vacuum) {
      _drawVacuum(canvas, startX + width * 0.7, y);
    }
  }

  void _drawPaddle(Canvas canvas, double x, double y, bool isLeft, Color color) {
    final paddlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(x, y);
      path.lineTo(x - 20, y - 10);
      path.lineTo(x - 20, y + 10);
      path.close();
    } else {
      path.moveTo(x, y);
      path.lineTo(x + 20, y - 10);
      path.lineTo(x + 20, y + 10);
      path.close();
    }
    canvas.drawPath(path, paddlePaint);
  }

  void _drawPlunger(Canvas canvas, double x, double y, bool isDown) {
    final plungerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    if (isDown) {
      canvas.drawRect(Rect.fromLTWH(x - 5, y - 20, 10, 20), plungerPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(x - 5, y - 40, 10, 20), plungerPaint);
    }
  }

  void _drawVacuum(Canvas canvas, double x, double y) {
    final vacuumPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    // Vacuum indicator (pulsing circle)
    final pulseRadius = 15 + (pulseAnimation.value * 5);
    final pulsePaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.5 * pulseAnimation.value)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pulseRadius, pulsePaint);
    canvas.drawCircle(Offset(x, y), 10, vacuumPaint);
  }

  void _drawComponentStatus(Canvas canvas, double startX, double y, double width, double height) {
    // Conveyor status
    _drawStatusBadge(
      canvas,
      startX + width / 2,
      y - height / 2 - 40,
      'Conveyor: ${state.conveyor ? "ON" : "OFF"}',
      state.conveyor ? Colors.green : Colors.grey,
    );

    // System status
    _drawStatusBadge(
      canvas,
      startX + width / 2,
      y + height / 2 + 40,
      'System: ${_getSystemStatusText()}',
      _getSystemStatusColor(),
    );
  }

  void _drawStatusBadge(Canvas canvas, double x, double y, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: textPainter.width + 16,
        height: 20,
      ),
      const Radius.circular(10),
    );

    final badgePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRect, badgePaint);

    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  Color _getPartColor(PartMaterial material) {
    switch (material) {
      case PartMaterial.steel:
        return Colors.grey;
      case PartMaterial.aluminium:
        return Colors.lightBlue;
      case PartMaterial.plastic:
        return Colors.orange;
    }
  }

  String _getMaterialLabel(PartMaterial material) {
    switch (material) {
      case PartMaterial.steel:
        return 'S';
      case PartMaterial.aluminium:
        return 'A';
      case PartMaterial.plastic:
        return 'P';
    }
  }

  String _getSystemStatusText() {
    if (state.activeFault != FaultType.none) {
      return 'FAULT';
    } else if (state.isRunning) {
      return 'RUNNING';
    } else {
      return 'STOPPED';
    }
  }

  Color _getSystemStatusColor() {
    if (state.activeFault != FaultType.none) {
      return Colors.red;
    } else if (state.isRunning) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(_FactoryPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.parts.length != parts.length ||
        oldDelegate.showSensorZones != showSensorZones ||
        oldDelegate.showComponentStatus != showComponentStatus ||
        oldDelegate.showPartLabels != showPartLabels;
  }
}

class _ControlsOverlay extends StatelessWidget {
  final SimulatorState state;
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ControlsOverlay({
    required this.state,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
            tooltip: 'Zoom Out',
          ),
          // Zoom level display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(zoomLevel * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Reset view
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: onReset,
            tooltip: 'Reset View',
          ),
          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: onZoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(width: 16),
          // System status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.isRunning
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.isRunning ? Colors.green : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isRunning ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isRunning ? 'Running' : 'Stopped',
                  style: TextStyle(
                    color: state.isRunning ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizationLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _LegendItem(color: Colors.grey, label: 'Steel'),
          _LegendItem(color: Colors.lightBlue, label: 'Aluminium'),
          _LegendItem(color: Colors.orange, label: 'Plastic'),
          const SizedBox(height: 4),
          _LegendItem(color: Colors.blue, label: 'First Gate', isSensor: true),
          _LegendItem(color: Colors.orange, label: 'Inductive/Cap', isSensor: true),
          _LegendItem(color: Colors.purple, label: 'Photo Gate', isSensor: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSensor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isSensor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSensor ? 12 : 16,
            height: isSensor ? 12 : 16,
            decoration: BoxDecoration(
              color: color,
              shape: isSensor ? BoxShape.circle : BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

