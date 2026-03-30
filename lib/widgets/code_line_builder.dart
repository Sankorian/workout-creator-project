import 'package:flutter/material.dart';
import '../constants/attribute_explanations.dart';

/// Reusable widget for rendering code-like lines with clickable attribute names
/// and optional placeholder comments above them.
class CodeLineWithComment extends StatelessWidget {
  /// The attribute name to display (e.g., 'name', 'growthLevel')
  final String label;

  /// The input widget to display after the label
  final Widget input;

  /// Whether this attribute has a visible comment
  final bool hasComment;

  /// Optional key to resolve explanation text; defaults to [label].
  final String? commentKey;

  /// Callback when the attribute name is clicked to toggle comment
  final VoidCallback onLabelTap;

  /// Whether in edit mode (shows '..' prefix instead of just spaces)
  final bool isEditing;

  /// Whether in view-only mode (shows ';' suffix instead of ',')
  final bool isViewing;

  const CodeLineWithComment({
    super.key,
    required this.label,
    required this.input,
    required this.hasComment,
    required this.onLabelTap,
    required this.isEditing,
    required this.isViewing,
    this.commentKey,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = isEditing && !isViewing ? '  ..' : '  ';
    final suffix = isEditing || isViewing ? ';' : ',';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Comment line that appears above the attribute
        if (hasComment)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              formatAttributeComment(commentKey ?? label),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        // Main code line
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(prefix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onLabelTap,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Text(' = ', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                input,
                const SizedBox(width: 4),
                Text(suffix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable widget for rendering section headers (like growthRules, decayRules, sets, etc.)
/// with clickable names and optional placeholder comments above them.
class CodeSectionHeader extends StatelessWidget {
  /// The section name (e.g., 'growthRules', 'involvedMuscles', 'batches')
  final String label;

  /// Whether this section header has a visible comment
  final bool hasComment;

  /// Optional key to resolve explanation text; defaults to [label].
  final String? commentKey;

  /// Callback when the header name is clicked to toggle comment
  final VoidCallback onLabelTap;

  /// Whether in edit mode (shows '..' prefix instead of just spaces)
  final bool isEditing;

  const CodeSectionHeader({
    super.key,
    required this.label,
    required this.hasComment,
    required this.onLabelTap,
    required this.isEditing,
    this.commentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Comment line that appears above the section header
        if (hasComment)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              formatAttributeComment(commentKey ?? label),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        // Section header line
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? '  ..' : '  ', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onLabelTap,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Text(isEditing ? ' = [' : ': [', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper mixin to manage comment state for screens
mixin CommentStateManager {
  final Set<String> attributesWithComments = {};

  void toggleComment(String key) {
    if (attributesWithComments.contains(key)) {
      attributesWithComments.remove(key);
    } else {
      attributesWithComments.add(key);
    }
  }

  bool hasComment(String key) => attributesWithComments.contains(key);
}

