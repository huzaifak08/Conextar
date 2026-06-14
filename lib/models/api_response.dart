class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  /// Factory helper to format successful pipelines
  factory ApiResponse.success(String message, T data) {
    return ApiResponse(status: true, message: message, data: data);
  }

  /// Factory helper to capture failed states (both network 400/500 errors or body logic failures)
  factory ApiResponse.error(String message) {
    return ApiResponse(status: false, message: message, data: null);
  }
}
