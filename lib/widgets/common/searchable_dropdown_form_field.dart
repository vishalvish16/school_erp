// =============================================================================
// FILE: lib/widgets/common/searchable_dropdown_form_field.dart
// PURPOSE: Searchable dropdown - type to search and select, no scrolling needed
// =============================================================================

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';

/// A searchable dropdown form field. Users can type to filter and select items.
/// Use [items] for simple string lists (value = display).
/// Use [valueItems] for value/label pairs (e.g. id + name).
///
/// On narrow viewports (under [AppBreakpoints.formMaxWidth], i.e. list screens
/// below 600px width), the popup uses a modal bottom sheet. Set
/// [useBottomSheet] to true to force that on wider layouts too (e.g. long lists).
class SearchableDropdownFormField<T> extends StatelessWidget {
  const SearchableDropdownFormField({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.decoration,
    this.validator,
    this.hintText,
    this.enabled = true,
    this.useBottomSheet = false,
  })  : valueItems = null;

  /// For value/label pairs: pass list of (value, label).
  /// [useBottomSheet] true forces a modal bottom sheet on all widths (helps with
  /// very long lists / overlay issues). Narrow widths use a bottom sheet automatically.
  const SearchableDropdownFormField.valueItems({
    super.key,
    this.value,
    required this.valueItems,
    this.onChanged,
    this.decoration,
    this.validator,
    this.hintText,
    this.enabled = true,
    this.useBottomSheet = false,
  })  : items = null;

  final T? value;
  final List<T>? items;
  final List<MapEntry<T, String>>? valueItems;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final String? hintText;
  final bool enabled;
  final bool useBottomSheet;

  List<_Item<T>> get _allItems {
    if (items != null) {
      return items!.map((v) => _Item(v, v.toString())).toList();
    }
    return valueItems!.map((e) => _Item(e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _allItems;
    final selected = value != null
        ? all.where((i) => _eq(i.value, value)).firstOrNull
        : null;

    final effectiveBottomSheet = useBottomSheet ||
        MediaQuery.sizeOf(context).width < AppBreakpoints.formMaxWidth;

    final searchDecoration = InputDecoration(
      hintText: 'Type to search...',
      prefixIcon: const Icon(Icons.search, size: 20),
      border: OutlineInputBorder(borderRadius: AppRadius.brMd),
      contentPadding:
          EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );

    // Use itemAsString for display - avoids text overlap from dropdownBuilder
    // Use filterFn for search - package filters items when user types
    // Wrap in LayoutBuilder to avoid unconstrained constraints when inside Row without Expanded
    final dropdown = DropdownSearch<_Item<T>>(
      selectedItem: selected,
      enabled: enabled,
      items: (filter, cs) => all,
      filterFn: (item, filter) {
        final f = filter.trim().toLowerCase();
        if (f.isEmpty) return true;
        return item.label.toLowerCase().contains(f);
      },
      itemAsString: (item) => item.label,
      dropdownBuilder: (context, item) {
        final label = item?.label ?? '';
        final baseStyle = Theme.of(context).textTheme.bodyLarge;
        final fontSize = baseStyle?.fontSize ?? 16.0;
        // [Text] inside InputDecorator can still wrap on web. TextPainter +
        // CustomPaint applies ellipsis at layout time (same path as engine).
        return SizedBox(
          height: fontSize * 1.25,
          width: double.infinity,
          child: CustomPaint(
            painter: _SingleLineEllipsisPainter(
              text: label,
              style: baseStyle?.copyWith(height: 1.0),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        );
      },
      onChanged: enabled
          ? (item) => onChanged?.call(item?.value)
          : null,
      compareFn: (a, b) => _eq(a.value, b.value),
      validator: validator != null
          ? (v) => validator!(v?.value) // ignore: dead_code, dead_null_aware_expression
          : null,
      popupProps: effectiveBottomSheet
          ? PopupProps.modalBottomSheet(
              showSearchBox: true,
              scrollbarProps: const ScrollbarProps(thumbVisibility: true),
              searchFieldProps: TextFieldProps(
                autofocus: true,
                decoration: searchDecoration,
              ),
              modalBottomSheetProps: ModalBottomSheetProps(
                showDragHandle: true,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              itemBuilder: _searchableDropdownItemTile,
            )
          : PopupProps.menu(
              showSearchBox: true,
              scrollbarProps: const ScrollbarProps(thumbVisibility: true),
              searchFieldProps: TextFieldProps(
                autofocus: true,
                decoration: searchDecoration,
              ),
              fit: FlexFit.loose,
              constraints: BoxConstraints(
                minWidth: 260,
                maxWidth: 400,
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              itemBuilder: _searchableDropdownItemTile,
            ),
      decoratorProps: DropDownDecoratorProps(
        baseStyle: Theme.of(context).textTheme.bodyLarge,
        decoration: (decoration ?? const InputDecoration()).copyWith(
          hintText: hintText ?? 'Select',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          // Avoid measuring an invisible multi-line hint alongside the value.
          maintainHintSize: false,
          hintMaxLines: 1,
        ),
      ),
    );
    final widget = enabled ? dropdown : Opacity(
      opacity: 0.55,
      child: dropdown,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        if (hasBoundedWidth) return widget;
        return SizedBox(width: 200, child: widget);
      },
    );
  }

  bool _eq(T? a, T? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a == b;
  }
}

Widget _searchableDropdownItemTile<T>(
  BuildContext context,
  _Item<T> item,
  bool isDisabled,
  bool isSelected,
) {
  return ListTile(
    dense: true,
    title: Text(
      item.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _Item<T> {
  final T value;
  final String label;
  _Item(this.value, this.label);
}

/// Paints a single line with ellipsis using [TextPainter] (reliable on web).
class _SingleLineEllipsisPainter extends CustomPainter {
  _SingleLineEllipsisPainter({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.textScaler,
  });

  final String text;
  final TextStyle? style;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '\u2026',
      textScaler: textScaler,
    );
    try {
      tp.layout(maxWidth: size.width);
      tp.paint(canvas, Offset.zero);
    } finally {
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _SingleLineEllipsisPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.textScaler != textScaler;
  }
}
