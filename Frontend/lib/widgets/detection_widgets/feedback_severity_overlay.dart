import 'package:flutter/material.dart';
import '../../models/feedback_severity.dart';
import '../../services/feedback_service.dart';

class FeedbackSeverityOverlay extends StatefulWidget {
  final FeedbackSeverity severity;
  final VoidCallback onDismiss;
  final Duration displayDuration;
  final double? objectDistance;

  const FeedbackSeverityOverlay({
    super.key,
    required this.severity,
    required this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
    this.objectDistance,
  });

  @override
  State<FeedbackSeverityOverlay> createState() =>
      _FeedbackSeverityOverlayState();
}

class _FeedbackSeverityOverlayState extends State<FeedbackSeverityOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _provideFeedback();
    _scheduleAutoDismiss();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _provideFeedback() async {
    await FeedbackService().provideFeedback(widget.severity);
  }

  void _scheduleAutoDismiss() {
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.severity.color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.severity.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.severity.icon,
                      color: widget.severity.color,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.severity.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: widget.severity.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.severity.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  if (widget.objectDistance != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.severity.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.severity.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: widget.severity.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.objectDistance!.toStringAsFixed(1)} meters',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: widget.severity.color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vibration,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vibration: ${_getVibrationLabel(widget.severity)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Audio: "${widget.severity.audioMessage}"',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.severity.vibrationPulseCount,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: widget.severity.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.severity.vibrationPulseCount} pulse${widget.severity.vibrationPulseCount > 1 ? 's' : ''}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getVibrationLabel(FeedbackSeverity severity) {
    switch (severity.vibrationPulseCount) {
      case 1:
        return 'Single pulse';
      case 2:
        return 'Double pulse';
      case 3:
        return 'Triple pulse';
      default:
        return '${severity.vibrationPulseCount} pulses';
    }
  }
}
