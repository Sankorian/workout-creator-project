import 'package:flutter/material.dart';

/// A widget that makes attribute names clickable and displays a comment above them
/// when clicked. The comment appears on the line above the attribute, similar to
/// code comments in IDEs.
class ExplainableAttributeName extends StatefulWidget {
  /// The attribute name to display (e.g., 'name', 'growthLevel', etc.)
  final String attributeName;

  /// Whether a comment is currently visible for this attribute
  final bool showComment;

  /// Callback when the attribute name is clicked
  final VoidCallback? onTap;

  const ExplainableAttributeName({
    super.key,
    required this.attributeName,
    this.showComment = false,
    this.onTap,
  });

  @override
  State<ExplainableAttributeName> createState() => _ExplainableAttributeNameState();
}

class _ExplainableAttributeNameState extends State<ExplainableAttributeName> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Comment line that appears above the attribute
        if (widget.showComment)
          const Text(
            '  /// placeholder',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        // Clickable attribute name
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Text(
              widget.attributeName,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.black, // Keep it black, no underline
              ),
            ),
          ),
        ),
      ],
    );
  }
}
