class PaginationModel<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final pagination = json['pagination'] ?? {};
    return PaginationModel<T>(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 10,
      totalPages: pagination['totalPages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': data.map((e) => toJsonT(e)).toList(),
      'pagination': {
        'total': total,
        'page': page,
        'limit': limit,
        'totalPages': totalPages,
      },
    };
  }
}
