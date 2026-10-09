class CitySearchAdapter {
  CitySearchAdapter._();

  static const Map<String, String> _codeToBackendName = {
    'HCM': 'TP. Hồ Chí Minh',
    'DL': 'Đà Lạt',
    'VT': 'Vũng Tàu',
    'NT': 'Nha Trang',
    'HN': 'Hà Nội',
    'DN': 'Đà Nẵng',
    'CT': 'Cần Thơ',
    'SP': 'Sa Pa',
    'HUE': 'Huế',
    'QN': 'Quy Nhơn',
    'PT': 'Phan Thiết',
  };

  /// Maps local city ID/code (e.g. HCM, DL) or name to verified backend search term.
  /// Does not guess unknown cities; returns the input string if not matched.
  static String resolveBackendSearchCity(String cityIdOrName) {
    final trimmed = cityIdOrName.trim();
    if (trimmed.isEmpty) return '';

    final upper = trimmed.toUpperCase();
    if (_codeToBackendName.containsKey(upper)) {
      return _codeToBackendName[upper]!;
    }

    for (final entry in _codeToBackendName.entries) {
      if (entry.value.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }

    return trimmed;
  }
}
