import 'package:flutter/material.dart';
// Pastikan path ini sesuai dengan lokasi file adaptive_slider.dart di proyek Anda
import 'adaptive/adaptive_slider.dart'; 

class LevelSlider extends StatefulWidget {
  final String label;
  final List<String> valueLabels;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  const LevelSlider({
    super.key,
    required this.label,
    required this.valueLabels,
    required this.initialIndex,
    required this.onChanged,
  });

  @override
  State<LevelSlider> createState() => _LevelSliderState();
}

class _LevelSliderState extends State<LevelSlider> {
  late int _i = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label di tengah atas
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Slider dengan track abu-abu muda
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: const Color(0xFFB596E5), // Warna ungu untuk bagian aktif
              inactiveTrackColor: const Color(0xFFE0E0E0), // Abu-abu muda untuk bagian tidak aktif
              thumbColor: Colors.white, // Thumb putih
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayColor: const Color(0xFFB596E5).withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _i.toDouble(),
              min: 0,
              max: (widget.valueLabels.length - 1).toDouble(),
              divisions: widget.valueLabels.length - 1,
              onChanged: (v) {
                final next = v.round();
                if (next == _i) return;
                setState(() => _i = next);
                widget.onChanged(next);
              },
            ),
          ),
          
          // Persentase di bawah slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.valueLabels.length, (index) {
              final isSelected = index == _i;
              return Expanded(
                child: Center(
                  child: Text(
                    widget.valueLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? const Color(0xFFB596E5) // Ungu untuk yang terpilih
                          : const Color(0xFF9E9E9E), // Abu-abu untuk yang tidak terpilih
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}