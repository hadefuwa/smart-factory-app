import 'package:flutter/material.dart';
import '../models/simulator_state.dart';
import '../services/simulator_service.dart';
import '../services/plc_communication_service.dart';
import 'sf_data_stream_log_screen.dart';

class SFSettingsScreen extends StatefulWidget {
  const SFSettingsScreen({super.key});

  @override
  State<SFSettingsScreen> createState() => _SFSettingsScreenState();
}

class _SFSettingsScreenState extends State<SFSettingsScreen> {
  double _speedScaling = 1.0;
  bool _randomFaults = false;
  bool _isLiveMode = true; // Default to live mode
  String _plcIpAddress = '192.168.7.2';
  String? _selectedIpPreset; // null = custom, otherwise the preset IP
  int _rack = 0;
  int _slot = 1;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _rackController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();
  final PLCCommunicationService _plcService = PLCCommunicationService();
  bool _isConnecting = false;
  
  static const List<String> _ipPresets = [
    '192.168.7.2',
    '192.168.0.99',
  ];
  
  final Map<PartMaterial, double> _materialMix = {
    PartMaterial.steel: 33.0,
    PartMaterial.aluminium: 33.0,
    PartMaterial.plastic: 34.0,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _plcService.initialize();
    setState(() {
      _isLiveMode = _plcService.isLiveMode;
      _plcIpAddress = _plcService.plcIpAddress;
      _rack = _plcService.rack;
      _slot = _plcService.slot;
      _ipController.text = _plcIpAddress;
      _rackController.text = _rack.toString();
      _slotController.text = _slot.toString();
      
      // Determine if current IP matches a preset
      if (_ipPresets.contains(_plcIpAddress)) {
        _selectedIpPreset = _plcIpAddress;
      } else {
        _selectedIpPreset = null; // Custom IP
      }
    });
    
    // Auto-connect if live mode is enabled
    if (_isLiveMode && !_plcService.isConnected) {
      setState(() => _isConnecting = true);
      final connected = await _plcService.connect();
      setState(() => _isConnecting = false);
      if (connected) {
        _showMessage('Auto-connected to PLC');
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _rackController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  Future<void> _handleModeChange(bool isLive) async {
    if (isLive == _isLiveMode) return;

    setState(() {
      _isConnecting = isLive;
    });

    await _plcService.setLiveMode(isLive);
    
    if (isLive) {
      final connected = await _plcService.connect();
      if (!connected) {
        _showMessage('Failed to connect to PLC. Check IP address and try again.');
      }
    }

    setState(() {
      _isLiveMode = isLive;
      _isConnecting = false;
    });
  }

  Future<void> _handleIpChange() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty || newIp == _plcIpAddress) return;

    // Basic IP validation
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(newIp)) {
      _showMessage('Invalid IP address format');
      _ipController.text = _plcIpAddress;
      return;
    }

    await _plcService.setPlcIpAddress(newIp);
    setState(() {
      _plcIpAddress = newIp;
      // Update preset selection if it matches
      if (_ipPresets.contains(newIp)) {
        _selectedIpPreset = newIp;
      } else {
        _selectedIpPreset = null; // Custom IP
      }
    });
    _showMessage('PLC IP address updated');
  }
  
  Future<void> _handleIpPresetChange(String? preset) async {
    setState(() {
      _selectedIpPreset = preset;
      if (preset != null) {
        // Preset selected, update IP
        _plcIpAddress = preset;
        _ipController.text = preset;
      }
      // If null (Custom), keep current IP in text field
    });
    
    if (preset != null) {
      await _plcService.setPlcIpAddress(preset);
      _showMessage('PLC IP address updated to $preset');
    }
  }

  Future<void> _handleRackSlotChange() async {
    final rack = int.tryParse(_rackController.text.trim()) ?? 0;
    final slot = int.tryParse(_slotController.text.trim()) ?? 1;
    
    if (rack < 0 || rack > 7) {
      _showMessage('Rack must be between 0 and 7');
      _rackController.text = _rack.toString();
      return;
    }
    
    if (slot < 0 || slot > 31) {
      _showMessage('Slot must be between 0 and 31');
      _slotController.text = _slot.toString();
      return;
    }
    
    await _plcService.setRackSlot(rack, slot);
    setState(() {
      _rack = rack;
      _slot = slot;
    });
    _showMessage('Rack/Slot updated');
  }

  @override
  Widget build(BuildContext context) {
    final simulator = SimulatorService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Connection Mode',
              icon: Icons.settings_ethernet,
              child: Column(
                children: [
                  // Connection Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLiveMode
                          ? (_plcService.isConnected 
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2))
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isLiveMode
                            ? (_plcService.isConnected ? Colors.green : Colors.orange)
                            : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isLiveMode
                              ? (_plcService.isConnected 
                                  ? Icons.link 
                                  : Icons.link_off)
                              : Icons.computer,
                          color: _isLiveMode
                              ? (_plcService.isConnected ? Colors.green : Colors.orange)
                              : Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLiveMode ? 'Live Mode' : 'Simulation Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _isLiveMode
                                      ? (_plcService.isConnected ? Colors.green : Colors.orange)
                                      : Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isConnecting
                                    ? 'Connecting to PLC...'
                                    : _isLiveMode
                                        ? (_plcService.isConnected
                                            ? 'Connected to $_plcIpAddress'
                                            : 'Not connected')
                                        : 'Using simulated data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mode Selection
                  _RadioTile(
                    title: 'Live',
                    subtitle: 'Connect to real hardware via PLC',
                    value: true,
                    groupValue: _isLiveMode,
                    icon: Icons.link,
                    color: Colors.green,
                    onChanged: _isConnecting ? null : (value) => _handleModeChange(true),
                  ),
                  const SizedBox(height: 8),
                  _RadioTile(
                    title: 'Simulation',
                    subtitle: 'Run with simulated data',
                    value: false,
                    groupValue: _isLiveMode,
                    icon: Icons.computer,
                    color: Colors.blue,
                    onChanged: _isConnecting ? null : (value) => _handleModeChange(false),
                  ),
                  if (_isLiveMode) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    // IP Preset Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedIpPreset,
                      decoration: InputDecoration(
                        labelText: 'PLC IP Address Preset',
                        prefixIcon: const Icon(Icons.list),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      items: [
                        ..._ipPresets.map((ip) => DropdownMenuItem(
                          value: ip,
                          child: Text(ip),
                        )),
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: _handleIpPresetChange,
                    ),
                    // Custom IP Text Field (only shown when Custom is selected)
                    if (_selectedIpPreset == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'Custom PLC IP Address',
                          hintText: '192.168.7.2',
                          prefixIcon: const Icon(Icons.settings_ethernet),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: _handleIpChange,
                            tooltip: 'Save IP address',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _handleIpChange(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rackController,
                            decoration: InputDecoration(
                              labelText: 'Rack',
                              hintText: '0',
                              prefixIcon: const Icon(Icons.grid_view),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _handleRackSlotChange(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _slotController,
                            decoration: InputDecoration(
                              labelText: 'Slot',
                              hintText: '1',
                              prefixIcon: const Icon(Icons.view_module),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: _handleRackSlotChange,
                                tooltip: 'Save rack/slot',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _handleRackSlotChange(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isConnecting
                                ? null
                                : () async {
                                    if (_plcService.isConnected) {
                                      _plcService.disconnect();
                                      _showMessage('Disconnected from PLC');
                                    } else {
                                      setState(() => _isConnecting = true);
                                      final connected = await _plcService.connect();
                                      setState(() => _isConnecting = false);
                                      if (connected) {
                                        _showMessage('Connected to PLC');
                                      } else {
                                        _showMessage('Failed to connect. Check IP address.');
                                      }
                                    }
                                    setState(() {});
                                  },
                            icon: Icon(
                              _plcService.isConnected ? Icons.link_off : Icons.link,
                            ),
                            label: Text(
                              _plcService.isConnected ? 'Disconnect' : 'Connect',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _plcService.isConnected 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DataStreamLogScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Log'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionCard(
              title: 'Simulator',
              icon: Icons.speed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speed Scaling: ${_speedScaling.toStringAsFixed(1)}x',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _speedScaling,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: '${_speedScaling.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() => _speedScaling = value);
                      simulator.setSpeedScaling(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Material Mix',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _MaterialSlider(
                    label: 'Steel',
                    value: _materialMix[PartMaterial.steel]!,
                    color: Colors.grey,
                    onChanged: (value) {
                      setState(() {
                        _materialMix[PartMaterial.steel] = value;
                        _updateMaterialMix();
                      });
                      simulator.setMaterialMix({
                        PartMaterial.steel: value / 100,
                        PartMaterial.aluminium: _materialMix[PartMaterial.aluminium]! / 100,
                        PartMaterial.plastic: _materialMix[PartMaterial.plastic]! / 100,
                      });
                    },
                  ),
                  _MaterialSlider(
                    label: 'Aluminium',
                    value: _materialMix[PartMaterial.aluminium]!,
                    color: Colors.lightBlue,
                    onChanged: (value) {
                      setState(() {
                        _materialMix[PartMaterial.aluminium] = value;
                        _updateMaterialMix();
                      });
                      simulator.setMaterialMix({
                        PartMaterial.steel: _materialMix[PartMaterial.steel]! / 100,
                        PartMaterial.aluminium: value / 100,
                        PartMaterial.plastic: _materialMix[PartMaterial.plastic]! / 100,
                      });
                    },
                  ),
                  _MaterialSlider(
                    label: 'Plastic',
                    value: _materialMix[PartMaterial.plastic]!,
                    color: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        _materialMix[PartMaterial.plastic] = value;
                        _updateMaterialMix();
                      });
                      simulator.setMaterialMix({
                        PartMaterial.steel: _materialMix[PartMaterial.steel]! / 100,
                        PartMaterial.aluminium: _materialMix[PartMaterial.aluminium]! / 100,
                        PartMaterial.plastic: value / 100,
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionCard(
              title: 'Faults',
              icon: Icons.warning,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Random Faults'),
                    subtitle: const Text('Randomly inject faults during operation'),
                    value: _randomFaults,
                    onChanged: (value) {
                      setState(() => _randomFaults = value);
                      simulator.setRandomFaults(value);
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Inject Fault',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _FaultButton(
                    label: 'E-Stop',
                    icon: Icons.emergency,
                    color: Colors.red,
                    onPressed: () {
                      simulator.injectFault(FaultType.eStop);
                      _showMessage('E-Stop fault injected');
                    },
                  ),
                  const SizedBox(height: 8),
                  _FaultButton(
                    label: 'Sensor Stuck',
                    icon: Icons.sensors_off,
                    color: Colors.orange,
                    onPressed: () {
                      simulator.injectFault(FaultType.sensorStuck);
                      _showMessage('Sensor stuck fault injected');
                    },
                  ),
                  const SizedBox(height: 8),
                  _FaultButton(
                    label: 'Paddle Jam',
                    icon: Icons.warning,
                    color: Colors.amber,
                    onPressed: () {
                      simulator.injectFault(FaultType.paddleJam);
                      _showMessage('Paddle jam fault injected');
                    },
                  ),
                  const SizedBox(height: 8),
                  _FaultButton(
                    label: 'Vacuum Leak',
                    icon: Icons.leak_add,
                    color: Colors.purple,
                    onPressed: () {
                      simulator.injectFault(FaultType.vacuumLeak);
                      _showMessage('Vacuum leak fault injected');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionCard(
              title: 'About',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Factory Control App',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.6',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A teaching and control companion for the Smart Factory training rig.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Help:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _HelpItem(
                    icon: Icons.home,
                    text: 'Home: View status and control the system',
                  ),
                  _HelpItem(
                    icon: Icons.play_arrow,
                    text: 'Run: Configure recipes and manual jog',
                  ),
                  _HelpItem(
                    icon: Icons.cable,
                    text: 'I/O: Monitor and control inputs/outputs',
                  ),
                  _HelpItem(
                    icon: Icons.assignment,
                    text: 'Worksheets: Complete guided learning activities',
                  ),
                  _HelpItem(
                    icon: Icons.analytics,
                    text: 'Analytics: View charts and export data',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMaterialMix() {
    final total = _materialMix.values.reduce((a, b) => a + b);
    if ((total - 100).abs() > 1) {
      // Auto-adjust to keep total at 100
      final factor = 100 / total;
      _materialMix.forEach((key, value) {
        _materialMix[key] = value * factor;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool groupValue;
  final ValueChanged<bool?>? onChanged;
  final IconData? icon;
  final Color? color;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final tileColor = color ?? Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? tileColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? tileColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? tileColor : Colors.white.withValues(alpha: 0.6),
                size: 24,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? tileColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: tileColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _MaterialSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FaultButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _FaultButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
