class SearchUtils {
  const SearchUtils._();

  static List<T> filterByQuery<T>(List<T> items, String query, bool Function(T item, String q) matches) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) => matches(item, q)).toList();
  }
}
