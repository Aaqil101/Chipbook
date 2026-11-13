import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_exception.dart';

/// Converts low-level Supabase failures into messages the UI can show.
RepositoryException supabaseFailure(String action, Object error) {
  if (error is PostgrestException) {
    return RepositoryException('$action: ${error.message}', error);
  }

  if (kDebugMode) {
    debugPrint('$action failed: $error');
  }

  // A response we cannot parse is a code or schema mismatch, not a network
  // problem, so do not tell the user to check their connection.
  if (error is TypeError ||
      error is FormatException ||
      error is ArgumentError) {
    return RepositoryException(
      '$action: the server sent an unexpected response.',
      error,
    );
  }

  return RepositoryException(
    '$action. Check your connection and try again.',
    error,
  );
}
