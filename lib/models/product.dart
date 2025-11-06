class Product {
  final String id;
  final String name;
  final String description;
  final String url;
  final String icon;
  final String imagePath;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
    required this.imagePath,
  });

  static List<Product> getProducts() {
    return [
      Product(
        id: 'IM0004',
        name: 'Maintenance of Closed Loop Systems',
        description: 'Comprehensive training platform for industrial maintenance technicians. Master closed-loop control systems through interactive worksheets and real-world scenarios.',
        url: 'https://matrixtsl.github.io/IM0004/index.html',
        icon: '⚙️',
        imagePath: 'assets/IM0004.jpeg',
      ),
      Product(
        id: 'IM6930',
        name: 'PLC Fundamentals',
        description: 'Hands-on training platform designed specifically for those new to industrial maintenance and automation. Features a Siemens S7-1214 PLC and 7-inch Unified Basic HMI.',
        url: 'https://matrixtsl.github.io/IM6930/index.html',
        icon: '🔧',
        imagePath: 'assets/IM6930.jpeg',
      ),
      Product(
        id: 'IM3214',
        name: 'Matrix LOGO!',
        description: 'Modular industrial control training system introducing learners to core concepts in industrial automation and programmable control. Features a Siemens LOGO! PLC.',
        url: 'https://matrixtsl.github.io/IM3214/',
        icon: '📡',
        imagePath: 'assets/IM3490.jpeg', // Using available image
      ),
    ];
  }
}

