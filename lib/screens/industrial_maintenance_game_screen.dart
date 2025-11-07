import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/logo_widget.dart';

class IndustrialMaintenanceGameScreen extends StatefulWidget {
  const IndustrialMaintenanceGameScreen({super.key});

  @override
  State<IndustrialMaintenanceGameScreen> createState() => _IndustrialMaintenanceGameScreenState();
}

class _IndustrialMaintenanceGameScreenState extends State<IndustrialMaintenanceGameScreen> {
  final List<Equipment> _equipment = [
    Equipment(
      name: 'Control Valve',
      icon: Icons.water_drop,
      problems: [
        Problem(
          description: 'Valve stuck in closed position',
          solution: 'Check actuator pressure and lubricate valve stem',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Valve leaking when closed',
          solution: 'Replace valve seat or seal',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Valve not responding to PLC signal',
          solution: 'Check wiring connections and PLC output module',
          difficulty: 'Hard',
        ),
      ],
    ),
    Equipment(
      name: 'Centrifugal Pump',
      icon: Icons.water_drop,
      problems: [
        Problem(
          description: 'Pump not starting',
          solution: 'Check motor overload protection and power supply',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Low flow rate',
          solution: 'Check for cavitation, impeller damage, or blocked inlet',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Excessive vibration',
          solution: 'Check bearing wear, impeller balance, and alignment',
          difficulty: 'Hard',
        ),
      ],
    ),
    Equipment(
      name: 'PLC Controller',
      icon: Icons.memory,
      problems: [
        Problem(
          description: 'PLC not communicating',
          solution: 'Check network cable and communication settings',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Input module not reading sensors',
          solution: 'Verify sensor wiring and check input module status LED',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Program logic error',
          solution: 'Review ladder logic and check for incorrect timers/counters',
          difficulty: 'Hard',
        ),
      ],
    ),
    Equipment(
      name: 'Pressure Sensor',
      icon: Icons.speed,
      problems: [
        Problem(
          description: 'Sensor reading zero',
          solution: 'Check sensor wiring and power supply',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Inaccurate readings',
          solution: 'Calibrate sensor or check for contamination',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Sensor output stuck at maximum',
          solution: 'Replace sensor or check for overpressure damage',
          difficulty: 'Hard',
        ),
      ],
    ),
    Equipment(
      name: 'Motor Starter',
      icon: Icons.power,
      problems: [
        Problem(
          description: 'Starter not engaging',
          solution: 'Check coil voltage and contactor condition',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Overload tripping frequently',
          solution: 'Check motor current draw and thermal overload settings',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Contacts welding shut',
          solution: 'Replace contactor - likely due to excessive current',
          difficulty: 'Hard',
        ),
      ],
    ),
    Equipment(
      name: 'Flow Meter',
      icon: Icons.analytics,
      problems: [
        Problem(
          description: 'No flow reading',
          solution: 'Check sensor installation and wiring',
          difficulty: 'Easy',
        ),
        Problem(
          description: 'Flow reading too high',
          solution: 'Calibrate meter or check for air bubbles in line',
          difficulty: 'Medium',
        ),
        Problem(
          description: 'Erratic readings',
          solution: 'Check for flow disturbances and verify sensor alignment',
          difficulty: 'Hard',
        ),
      ],
    ),
  ];

  Equipment? _selectedEquipment;
  Problem? _currentProblem;
  bool _showSolution = false;
  int _score = 0;
  int _problemsSolved = 0;
  final List<String> _diagnosisHistory = [];

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  void _generateNewProblem() {
    final random = math.Random();
    final equipment = _equipment[random.nextInt(_equipment.length)];
    final problem = equipment.problems[random.nextInt(equipment.problems.length)];
    
    setState(() {
      _selectedEquipment = equipment;
      _currentProblem = problem;
      _showSolution = false;
    });
  }

  void _checkDiagnosis(String diagnosis) {
    setState(() {
      _diagnosisHistory.add('${_selectedEquipment!.name}: $diagnosis');
      _showSolution = true;
    });
  }

  void _nextProblem() {
    if (_showSolution) {
      setState(() {
        _problemsSolved++;
        _score += _currentProblem!.difficulty == 'Easy' ? 10 : 
                  _currentProblem!.difficulty == 'Medium' ? 20 : 30;
        _showSolution = false;
      });
    }
    _generateNewProblem();
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _problemsSolved = 0;
      _diagnosisHistory.clear();
      _showSolution = false;
    });
    _generateNewProblem();
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
              child: const Text(
                'Industrial Maintenance',
                style: TextStyle(
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
          IconButton(
            icon: Icon(Icons.refresh, color: purple),
            onPressed: _resetGame,
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Card
                _buildScoreCard(context, purple),
                const SizedBox(height: 16),
                
                // Equipment Display
                if (_selectedEquipment != null && _currentProblem != null)
                  _buildEquipmentCard(context, purple),
                
                const SizedBox(height: 16),
                
                // Problem Description
                if (_currentProblem != null)
                  _buildProblemCard(context, purple),
                
                const SizedBox(height: 16),
                
                // Diagnosis Options
                if (!_showSolution && _currentProblem != null)
                  _buildDiagnosisOptions(context, purple),
                
                // Solution Display
                if (_showSolution && _currentProblem != null)
                  _buildSolutionCard(context, purple),
                
                const SizedBox(height: 16),
                
                // Next Problem Button
                if (_showSolution)
                  FilledButton.icon(
                    onPressed: _nextProblem,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next Problem'),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // History
                if (_diagnosisHistory.isNotEmpty)
                  _buildHistoryCard(context, purple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Color purple) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Score',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_score',
                style: TextStyle(
                  color: purple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: purple.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              Text(
                'Solved',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_problemsSolved',
                style: TextStyle(
                  color: purple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, Color purple) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedEquipment!.icon,
              color: purple,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEquipment!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(_currentProblem!.difficulty).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Difficulty: ${_currentProblem!.difficulty}',
                    style: TextStyle(
                      color: _getDifficultyColor(_currentProblem!.difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCard(BuildContext context, Color purple) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Problem Reported',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentProblem!.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisOptions(BuildContext context, Color purple) {
    // Generate plausible wrong answers
    final wrongAnswers = [
      'Check power supply',
      'Replace entire unit',
      'Restart the system',
      'Clean the equipment',
      'Update firmware',
      'Check network connection',
    ];
    
    final allOptions = [
      _currentProblem!.solution,
      ...wrongAnswers.take(3),
    ]..shuffle();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'What\'s your diagnosis?',
                style: TextStyle(
                  color: purple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...allOptions.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDiagnosisButton(context, purple, option),
          )),
        ],
      ),
    );
  }

  Widget _buildDiagnosisButton(BuildContext context, Color purple, String diagnosis) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _checkDiagnosis(diagnosis),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: purple.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          diagnosis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSolutionCard(BuildContext context, Color purple) {
    final isCorrect = _diagnosisHistory.isNotEmpty && 
                      _diagnosisHistory.last.contains(_currentProblem!.solution);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect 
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your diagnosis: ${_diagnosisHistory.isNotEmpty ? _diagnosisHistory.last.split(': ').last : 'N/A'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solution: ${_currentProblem!.solution}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Color purple) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnosis History',
                style: TextStyle(
                  color: purple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._diagnosisHistory.reversed.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: purple.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Equipment {
  final String name;
  final IconData icon;
  final List<Problem> problems;

  Equipment({
    required this.name,
    required this.icon,
    required this.problems,
  });
}

class Problem {
  final String description;
  final String solution;
  final String difficulty;

  Problem({
    required this.description,
    required this.solution,
    required this.difficulty,
  });
}

