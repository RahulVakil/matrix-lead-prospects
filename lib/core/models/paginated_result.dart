class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    this.page = 1,
    this.pageSize = 20,
  });

  bool get hasMore => page * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}
