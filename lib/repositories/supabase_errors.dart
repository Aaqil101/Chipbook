import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_exception.dart';

/// Converts low-level Supabase failures into messages the UI can show.
RepositoryException supabaseFailure(String action, Object error) {
  if (error is PostgrestException) {
    return RepositoryException('$action: ${error.message}', error);
  }
  return RepositoryException(
    '$action. Check your connection and try again.',
    error,
  );
}
