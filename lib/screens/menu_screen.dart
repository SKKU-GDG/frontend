import 'package:flutter/material.dart';
import 'practice_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  // 메뉴 아이템 정보
  final List<_MenuItem> items = const [
    _MenuItem('Psychiatry', 'assets/images/psychiatry.png'),
    _MenuItem('Medical Treatment', 'assets/images/medical_treatment.png'),
    _MenuItem('Pharmacy', 'assets/images/pharmacy.png'),
    _MenuItem('Custom', 'assets/images/custom.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gap Ear'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAF7FF),
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFFAF7FF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,           
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.8,      
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              children: items.map((item) {
                return _MenuButton(item: item);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String assetPath;
  const _MenuItem(this.title, this.assetPath);
}

class _MenuButton extends StatelessWidget {
  final _MenuItem item;
  const _MenuButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeScreen(category: item.title),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Image.asset(item.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E0F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
