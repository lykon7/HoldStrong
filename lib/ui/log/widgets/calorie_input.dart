import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/calorie_library.dart';

class CalorieInput extends StatefulWidget {
  const CalorieInput({
    super.key,
    required this.controller,
    required this.labelController,
  });

  final TextEditingController controller;
  final TextEditingController labelController;

  @override
  State<CalorieInput> createState() => _CalorieInputState();
}

class _CalorieInputState extends State<CalorieInput> {
  List<MapEntry<String, int>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.labelController.addListener(_updateSuggestions);
  }

  void _updateSuggestions() {
    final results = CalorieLibrary.search(widget.labelController.text);
    setState(() => _suggestions = results.take(4).toList());
  }

  @override
  void dispose() {
    widget.labelController.removeListener(_updateSuggestions);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'kcal',
            suffixText: 'kcal',
            suffixStyle: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () => widget.controller.text = s.value.toString(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundElevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${s.key} ~${s.value} kcal',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
