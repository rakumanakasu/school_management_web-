import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.people, 'label': 'Students'},
      {'icon': Icons.person, 'label': 'Teachers'},
      {'icon': Icons.grade, 'label': 'Grades'},
      {'icon': Icons.check_circle, 'label': 'Attendance'},
    ];

    return Container(
      width: 220,
      height: double.infinity, // <-- full height
      color: const Color(0xFF1A237E), // Deep blue
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'School Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selected == index;
            return ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: isSelected ? Colors.yellowAccent : Colors.white70,
              ),
              title: Text(
                item['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.yellowAccent : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedTileColor: Colors.indigo.shade700,
              onTap: () => onSelect(index),
            );
          }),
        ],
      ),
    );
  }
}
