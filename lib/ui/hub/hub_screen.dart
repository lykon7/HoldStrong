import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _HubCard(
              title: 'Journal',
              icon: Icons.book_outlined,
              color: Colors.blueAccent,
              onTap: () => context.push('/hub/journal'),
            ),
            _HubCard(
              title: 'Wishlist',
              icon: Icons.star_border,
              color: Colors.amber,
              onTap: () => context.push('/hub/wishlist'),
            ),
            _HubCard(
              title: 'Workout',
              icon: Icons.fitness_center,
              color: Colors.orange,
              onTap: () => context.push('/hub/workout'),
            ),
            _HubCard(
              title: 'To-Do List',
              icon: Icons.checklist,
              color: Colors.teal,
              onTap: () => context.push('/hub/todo'),
            ),
            _HubCard(
              title: 'Liabilities',
              icon: Icons.receipt_long,
              color: Color(0xFF7C83FD),
              onTap: () => context.push('/hub/liabilities'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
