/// Exception thrown by [BookingService] for domain-specific errors.
class BookingException implements Exception {
  const BookingException({
    required this.code,
    required this.message,
    this.statusCode = 400,
  });

  final String code;
  final String message;
  final int statusCode;

  @override
  String toString() => 'BookingException($code): $message';
}
