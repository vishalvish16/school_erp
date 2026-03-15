// =============================================================================
// FILE: lib/widgets/common/address_location_picker.dart
// PURPOSE: Cascading Country → State → City picker for address fields
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/data/location_data.dart';
import 'searchable_dropdown_form_field.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Reusable cascading address picker: Country (first) → State → City.
/// State list updates when country changes; city list updates when state changes.
class AddressLocationPicker extends StatelessWidget {
  const AddressLocationPicker({
    super.key,
    required this.country,
    required this.state,
    required this.city,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.countryDecoration,
    this.stateDecoration,
    this.cityDecoration,
    this.countryLabel = 'Country',
    this.stateLabel = 'State',
    this.cityLabel = 'City',
    this.allowFreeTextCity = true,
    this.compact = false,
  });

  final String? country;
  final String? state;
  final String? city;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onCityChanged;
  final InputDecoration? countryDecoration;
  final InputDecoration? stateDecoration;
  final InputDecoration? cityDecoration;
  final String countryLabel;
  final String stateLabel;
  final String cityLabel;
  /// If true, show a text field for city when no cities in list, or allow typing
  final bool allowFreeTextCity;
  /// If true, use narrower layout (e.g. for filters)
  final bool compact;

  InputDecoration _defaultDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: AppRadius.brLg),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 14,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final countries = LocationData.countries;
    final states = country != null && country!.isNotEmpty
        ? LocationData.statesFor(country!)
        : <String>[];
    final cities = country != null &&
            state != null &&
            country!.isNotEmpty &&
            state!.isNotEmpty
        ? LocationData.citiesFor(country!, state!)
        : <String>[];

    final hasCityList = cities.isNotEmpty;
    final countryDeco = countryDecoration ?? _defaultDecoration(countryLabel);
    final stateDeco = stateDecoration ?? _defaultDecoration(stateLabel);
    final cityDeco = cityDecoration ?? _defaultDecoration(cityLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Country (first)
        SearchableDropdownFormField<String>(
          value: country != null && countries.contains(country) ? country : null,
          items: countries,
          decoration: countryDeco,
          hintText: 'Select $countryLabel',
          onChanged: (v) {
            onCountryChanged(v);
            onStateChanged(null);
            onCityChanged(null);
          },
        ),
        SizedBox(height: compact ? 8 : 12),
        // 2. State (updates per country)
        SearchableDropdownFormField<String>(
          value: state != null && states.contains(state) ? state : null,
          items: states,
          decoration: stateDeco,
          hintText: country != null ? 'Select $stateLabel' : 'Select country first',
          enabled: country != null,
          onChanged: country != null
              ? (v) {
                  onStateChanged(v);
                  onCityChanged(null);
                }
              : null,
        ),
        SizedBox(height: compact ? 8 : 12),
        // 3. City (updates per state)
        if (hasCityList)
          SearchableDropdownFormField<String>(
            value: city != null && (cities.contains(city) || city!.isNotEmpty) ? city : null,
            items: [
              ...cities,
              if (city != null && city!.isNotEmpty && !cities.contains(city)) city!,
            ],
            decoration: cityDeco,
            hintText: state != null ? 'Select $cityLabel' : 'Select state first',
            enabled: state != null,
            onChanged: state != null ? (v) => onCityChanged(v) : null,
          )
        else if (allowFreeTextCity)
          TextFormField(
            key: ValueKey('city_${country ?? ""}_${state ?? ""}_${city ?? ""}'),
            initialValue: city,
            decoration: cityDeco.copyWith(
              hintText: state != null ? 'Enter $cityLabel' : 'Select state first',
            ),
            onChanged: state != null
                ? (v) => onCityChanged(v.isEmpty ? null : v)
                : null,
            enabled: state != null,
          ),
      ],
    );
  }
}

/// Inline row version for horizontal layout (e.g. in forms with limited space)
class AddressLocationPickerRow extends StatelessWidget {
  const AddressLocationPickerRow({
    super.key,
    required this.country,
    required this.state,
    required this.city,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.flex = const [1, 1, 1],
  });

  final String? country;
  final String? state;
  final String? city;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onCityChanged;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    final countries = LocationData.countries;
    final states = country != null && country!.isNotEmpty
        ? LocationData.statesFor(country!)
        : <String>[];
    final cities = country != null &&
            state != null &&
            country!.isNotEmpty &&
            state!.isNotEmpty
        ? LocationData.citiesFor(country!, state!)
        : <String>[];

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: AppRadius.brLg),
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: flex[0],
          child: SearchableDropdownFormField<String>(
            value: country != null && countries.contains(country) ? country : null,
            items: countries,
            decoration: deco('Country'),
            onChanged: (v) {
              onCountryChanged(v);
              onStateChanged(null);
              onCityChanged(null);
            },
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          flex: flex[1],
          child: SearchableDropdownFormField<String>(
            value: state != null && states.contains(state) ? state : null,
            items: states,
            decoration: deco('State'),
            enabled: country != null,
            onChanged: country != null
                ? (v) {
                    onStateChanged(v);
                    onCityChanged(null);
                  }
                : null,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          flex: flex[2],
          child: cities.isNotEmpty
              ? SearchableDropdownFormField<String>(
                  value: city != null && cities.contains(city) ? city : null,
                  items: cities,
                  decoration: deco('City'),
                  enabled: state != null,
                  onChanged: state != null ? (v) => onCityChanged(v) : null,
                )
              : TextFormField(
                  initialValue: city,
                  decoration: deco('City').copyWith(hintText: 'Enter city'),
                  onChanged: state != null ? (v) => onCityChanged(v.isEmpty ? null : v) : null,
                  enabled: state != null,
                ),
        ),
      ],
    );
  }
}
