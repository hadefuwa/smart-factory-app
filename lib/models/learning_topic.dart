class LearningTopic {
  final String id;
  final String title;
  final String goal;
  final int estimatedMinutes;
  final String content;
  final List<String> keyPoints;

  LearningTopic({
    required this.id,
    required this.title,
    required this.goal,
    required this.estimatedMinutes,
    required this.content,
    required this.keyPoints,
  });

  static List<LearningTopic> getTopics() {
    return [
      LearningTopic(
        id: 'FL01',
        title: 'Factory Control and Automation Systems',
        goal: 'Master the fundamentals of factory automation and control architectures',
        estimatedMinutes: 50,
        content:
            'In-depth exploration of control system hierarchies, automation architectures, and integration strategies used in modern smart factories.',
        keyPoints: [
          'Study the control hierarchy: Field level (sensors/actuators) → Control level (PLC) → Supervisory level (HMI/SCADA)',
          'Understand the Smart Factory control architecture through I/O screen - observe how inputs flow to the controller and outputs respond',
          'Learn about distributed vs centralized control by comparing single-PLC operation with multi-controller scenarios',
          'Examine real-time control loops: observe sensor input → PLC logic → actuator output timing on the Run screen',
          'Study interlock logic and safety systems - test conveyor/plunger safety interlocks in I/O manual mode',
          'Understand sequence control and state machines - monitor production states (Idle/Running/Fault) on Home screen',
          'Review industrial communication protocols: S7 protocol in Settings → Network configuration',
          'Map the automation pyramid: analyze how this app implements Level 0 (I/O), Level 1 (PLC control), Level 2 (SCADA/HMI)',
          'Document the complete control flow from material entry to sorted delivery, identifying all control decision points',
        ],
      ),
      LearningTopic(
        id: 'FL02',
        title: 'Software Design for Automation',
        goal:
            'Learn software architecture patterns and design principles for automation systems',
        estimatedMinutes: 55,
        content:
            'Deep dive into automation software design including state machines, event-driven programming, real-time constraints, and modularity.',
        keyPoints: [
          'Study the state machine design pattern: trace system states (Stopped/Running/Fault/Reset) through a complete production cycle',
          'Understand event-driven architecture - observe how sensor events (First Gate trigger) initiate automated sequences',
          'Learn about real-time system requirements: monitor response time from sensor detection to actuator activation on I/O screen',
          'Examine modular system design: identify independent subsystems (conveyor, sorting, gantry) and their interfaces',
          'Study alarm and fault handling architecture: inject faults and trace fault detection → alarm generation → operator notification → reset',
          'Understand data persistence and logging: review Event Log to see how system events are captured and stored',
          'Learn about recipe management and configuration: create multiple recipes with different parameters on Run screen',
          'Study HMI design principles: evaluate the app\'s screen layout, navigation, real-time updates, and user feedback mechanisms',
          'Review communication protocol implementation: examine Data Stream Log to understand S7 protocol message structure and timing',
          'Document software quality attributes: analyze reliability (fault handling), maintainability (modular design), usability (interface), and performance (response time)',
        ],
      ),
      LearningTopic(
        id: 'FL03',
        title: 'DC Motor and Stepper Drives',
        goal: 'Master motor control theory and practice for DC and stepper motors',
        estimatedMinutes: 45,
        content:
            'Comprehensive study of DC motor speed control and stepper motor positioning, including control methods, drive electronics, and application considerations.',
        keyPoints: [
          'Learn DC motor fundamentals: understand how conveyor speed control (0-100%) translates to motor voltage/PWM on Run screen',
          'Study variable speed drive operation: test conveyor at 25%, 50%, 75%, 100% and observe throughput impact on Analytics',
          'Understand stepper motor basics: learn how step/direction signals control the gantry motor in I/O manual controls',
          'Practice stepper positioning: count steps to move gantry specific distances, calculate steps per mm/inch',
          'Study homing procedures: use Gantry Home sensor to establish zero position reference',
          'Learn about motor acceleration/deceleration: observe conveyor startup and shutdown ramp timing',
          'Understand torque requirements: observe system behavior when conveyor is loaded vs empty (simulation)',
          'Study microstepping concepts: understand how step resolution affects gantry positioning accuracy',
          'Compare DC vs stepper applications: analyze why DC motor is used for conveyor (continuous motion) vs stepper for gantry (positioning)',
          'Document motor performance parameters: speed range, positioning accuracy, response time, holding torque (gantry)',
        ],
      ),
      LearningTopic(
        id: 'FL04',
        title: 'Conveyor and Gantry Systems',
        goal:
            'Understand design, operation, and control of conveyor and gantry positioning systems',
        estimatedMinutes: 50,
        content:
            'Detailed exploration of conveyor material handling and XYZ gantry positioning systems including mechanics, sensors, and control strategies.',
        keyPoints: [
          'Study conveyor system components: motor drive, belt mechanism, speed control, material tracking sensors',
          'Understand material flow control: start conveyor, place items, track progression from First Gate → Inductive → Capacitive → Photo Gate',
          'Learn speed optimization: test different conveyor speeds (20%, 40%, 60%, 80%, 100%) and measure throughput vs accuracy trade-offs',
          'Study sensor placement strategy: understand why sensors are positioned at specific points along the conveyor path',
          'Examine gantry mechanics: understand X-axis (horizontal) positioning using stepper motor step counting',
          'Practice gantry homing sequence: move to home sensor, establish zero reference, position to known coordinates',
          'Learn coordinated motion: understand timing between conveyor stop → gantry move → plunger down → vacuum on',
          'Study end-of-travel protection: test gantry limits and observe safety stops (simulated)',
          'Understand material handling cycle time: measure total time from part detection to pick-and-place completion',
          'Optimize system performance: adjust conveyor speed and gantry acceleration to maximize throughput while maintaining reliability',
        ],
      ),
      LearningTopic(
        id: 'FL05',
        title: 'Vacuum Pick and Place Systems',
        goal:
            'Master pneumatic vacuum gripper systems for automated material handling',
        estimatedMinutes: 40,
        content:
            'Complete study of vacuum-based pick and place operations including gripper technology, vacuum generation, sequence control, and error handling.',
        keyPoints: [
          'Learn vacuum gripper fundamentals: understand how vacuum creates gripping force on parts',
          'Study vacuum system components: vacuum generator, gripper pad, vacuum sensor (verification)',
          'Understand pick sequence: conveyor stop → gantry position → plunger down → vacuum on → verify grip → plunger up',
          'Practice manual pick operation: use I/O screen manual controls to execute each step individually',
          'Learn place sequence: gantry move to drop location → plunger down → vacuum off → part release → plunger up',
          'Study grip verification: understand importance of vacuum sensing to detect pick failures',
          'Test vacuum failure scenarios: simulate vacuum leak fault from Settings, observe system response and error handling',
          'Understand cycle time optimization: measure pick-place cycle, identify time-consuming steps, plan improvements',
          'Study multi-part handling: understand how system handles different part sizes and materials',
          'Document complete pick-and-place program: create step-by-step sequence diagram with sensor checks and safety interlocks',
        ],
      ),
      LearningTopic(
        id: 'FL06',
        title: 'Component Sensing and Sorting',
        goal:
            'Master advanced sensing technologies and automated sorting logic for material classification',
        estimatedMinutes: 45,
        content:
            'In-depth study of multi-sensor material identification and high-speed sorting control including sensor selection, signal processing, and decision logic.',
        keyPoints: [
          'Study multi-sensor detection strategy: understand why three sensors (optical, inductive, capacitive) are needed for 3-material sorting',
          'Learn material classification logic: First Gate (presence) → Inductive (ferrous=steel) → Capacitive (non-ferrous=aluminum) → default=plastic',
          'Understand sensor signal timing: observe I/O screen sensor states as material moves through detection zone',
          'Study sorting decision algorithms: trace how sensor combinations determine Steel vs Aluminum vs Plastic classification',
          'Learn reject detection logic: understand what sensor patterns indicate defects or unidentifiable materials',
          'Practice building truth tables: create sensor state combinations for all material types (Steel, Aluminum, Plastic, Defect)',
          'Study paddle actuation timing: understand when Steel paddle or Aluminum paddle actuates based on material flow speed',
          'Understand position tracking: learn how system calculates material position from First Gate to paddle locations',
          'Test sorting accuracy: run batch with known materials, analyze sorting counters for accuracy percentage',
          'Optimize sorting performance: adjust conveyor speed to balance throughput vs sensor reliability and sorting accuracy',
          'Document complete sorting algorithm: create flowchart showing sensor inputs → classification logic → paddle outputs',
        ],
      ),
      LearningTopic(
        id: 'FL07',
        title: 'Multi-Controller System Design',
        goal:
            'Design and integrate systems with multiple PLCs and distributed control architectures',
        estimatedMinutes: 60,
        content:
            'Advanced topic covering distributed control systems, multi-PLC communication, task allocation, and system integration strategies for complex automation.',
        keyPoints: [
          'Understand multi-controller architectures: study when to use single vs multiple PLCs (system complexity, geographic distribution, safety isolation)',
          'Learn task allocation strategies: identify which subsystems could be separate controllers (conveyor PLC, gantry/robot PLC, quality inspection PLC)',
          'Study inter-PLC communication: understand how PLCs share data (conveyor position → robot controller, quality result → sorting controller)',
          'Design communication protocols: define data exchange requirements (cyclic data, event-driven messages, handshaking)',
          'Understand master/slave architectures: identify which controller is master (coordinator) vs slaves (subsystem controllers)',
          'Learn synchronization strategies: study how to coordinate multi-PLC timing (conveyor stops before robot picks)',
          'Study redundancy and failover: design backup controller strategies for critical systems',
          'Understand distributed I/O: learn how remote I/O modules connect to multiple controllers over networks',
          'Design a 3-PLC system for the Smart Factory: PLC1=Conveyor+Sensors, PLC2=Gantry+Vacuum, PLC3=Quality+Sorting',
          'Create data exchange specification: define all signals shared between PLCs (material present, position data, sort command, quality result)',
          'Document system integration: create network diagram showing all PLCs, I/O modules, HMI connections, and data flows',
        ],
      ),
    ];
  }
}
