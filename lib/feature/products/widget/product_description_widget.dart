import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../Core/Utils/appflowy_helper.dart';

class ProductDescriptionWidget extends StatefulWidget {
  final String description;

  const ProductDescriptionWidget({super.key, required this.description});

  @override
  State<ProductDescriptionWidget> createState() => _ProductDescriptionWidgetState();
}

class _ProductDescriptionWidgetState extends State<ProductDescriptionWidget> {
  EditorState? _editorState;
  EditorScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _parseDescription();
  }

  @override
  void didUpdateWidget(covariant ProductDescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _disposeEditor();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _parseDescription();
        if (mounted) setState(() {});
      });
    }
  }

  void _disposeEditor() {
    _scrollController?.dispose();
    _scrollController = null;
    _editorState = null;
  }

  void _parseDescription() {
    final text = widget.description.trim();
    if (text.isEmpty) {
      _disposeEditor();
      return;
    }

    try {
      final document = AppFlowyHelper.getAppFlowyDocument(text);
      final editorState = EditorState(document: document);
      _scrollController = EditorScrollController(editorState: editorState);
      _editorState = editorState;
    } catch (e) {
      debugPrint("Error loading description editor: $e");
    }
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.grey.shade300 : AppColors.textDark;
    final description = widget.description.trim();

    if (description.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Text(
          "No description available for this product.",
          style: TextStyle(
            color: isDark ? Colors.grey.shade500 : AppColors.textMuted,
            height: 1.5,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_editorState != null && _scrollController != null) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60, maxHeight: 350),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: AppFlowyEditor(
          editorState: _editorState!,
          editorScrollController: _scrollController!,
          editable: false,
          autoFocus: false,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: SelectableText(
        widget.description,
        style: TextStyle(color: textSecondary, height: 1.6, fontSize: 14),
      ),
    );
  }
}