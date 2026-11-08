import 'package:flutter/material.dart';

class BackgroundTransparencySlider extends StatelessWidget {
  final String title; // [추가] 제목 파라미터
  final double currentOpacity;
  final ValueChanged<double> onChanged;

  const BackgroundTransparencySlider({
    super.key,
    required this.title,
    required this.currentOpacity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, 
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: currentOpacity,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white10,
              ),
            ),
            Container(
              width: 45,
              alignment: Alignment.centerRight,
              child: Text("${(currentOpacity * 100).toInt()}%", 
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
