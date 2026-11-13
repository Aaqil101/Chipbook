/// A failure the UI can show to the user.
class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
