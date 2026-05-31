import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StarRatingWidget extends StatefulWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;
  final bool readOnly;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 36,
    this.readOnly = false,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _displayRating = 0;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.rating;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(StarRatingWidget old) {
    super.didUpdateWidget(old);
    _displayRating = widget.rating;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onStarTap(int index) {
    if (widget.readOnly) return;
    final newRating = index.toDouble();
    setState(() => _displayRating = newRating);
    widget.onRatingChanged(newRating);
    _pulseController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final isFilled = starIndex <= _displayRating;
        return GestureDetector(
          onTap: () => _onStarTap(starIndex),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) {
              final scale = isFilled && _pulseController.isAnimating
                  ? _pulseAnimation.value
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFilled ? AppColors.starColor : AppColors.lightTextMuted,
                    size: widget.starSize,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
