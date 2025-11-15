class ApiResponse<T> {
  final T? body;
  final int code;

  ApiResponse({required this.body, required this.code});
}
