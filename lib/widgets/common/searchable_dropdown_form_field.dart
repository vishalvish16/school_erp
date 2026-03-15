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
  /// Set [useBottomSheet] true for filters with many items (State/Country)
  /// to avoid overlay layout issues that cause hit-test errors.
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

    // Use itemAsString for display - avoids text overlap from dropdownBuilder
    // Use filterFn for search - package filters items when user types
    // Wrap in LayoutBuilder to avoid unconstrained constraints when inside Row without Expanded
    final dropdown = DropdownSearch<_Item<T>>(
      selectedItem: selected,
      enabled: enabled,
      items: (filter, cs) => all,
      filterFn: (item, filter) {
        final f = (filter ?? '').trim().toLowerCase();
        if (f.isEmpty) return true;
        return item.label.toLowerCase().contains(f);
      },
      itemAsString: (item) => item.label,
      onChanged: enabled
          ? (item) => onChanged?.call(item?.value)
          : null,
      compareFn: (a, b) => _eq(a.value, b.value),
      validator: validator != null
          ? (v) => validator!(v?.value) // ignore: dead_code, dead_null_aware_expression
          : null,
      popupProps: useBottomSheet
          ? PopupProps.modalBottomSheet(
              showSearchBox: true,
              scrollbarProps: const ScrollbarProps(thumbVisibility: true),
              searchFieldProps: TextFieldProps(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              itemBuilder: (context, item, isDisabled, isSelected) => ListTile(
                dense: true,
                title: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
            )
          : PopupProps.menu(
              showSearchBox: true,
              scrollbarProps: const ScrollbarProps(thumbVisibility: true),
              searchFieldProps: TextFieldProps(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                ),
              ),
              fit: FlexFit.loose,
              constraints: BoxConstraints(
                minWidth: 260,
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              itemBuilder: (context, item, isDisabled, isSelected) => ListTile(
                dense: true,
                title: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
            ),
      decoratorProps: DropDownDecoratorProps(
        decoration: (decoration ?? const InputDecoration()).copyWith(
          hintText: hintText ?? 'Select',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
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

class _Item<T> {
  final T value;
  final String label;
  _Item(this.value, this.label);
}
