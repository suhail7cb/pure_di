/// Interface for disposable services.
///
/// Implement this on any service class that needs to release
/// resources when it is no longer needed (e.g., close streams, connections).
abstract class Disposable {
  void dispose();
}
