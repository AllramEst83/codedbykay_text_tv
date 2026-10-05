/// Why a request failed, in the terms a reader cares about.
enum NetworkFailure {
  /// No connection to the site (no network, DNS, refused).
  offline,

  /// The site did not answer in time.
  timeout,

  /// The site answered with an error status (5xx and the like).
  server,

  /// The site answered, but not with anything this app understands: it has
  /// probably changed.
  changed,

  /// Anything else (a secure connection that could not be made, an answer far
  /// too large).
  other;

  /// Worth asking again a moment later: the next try may well work.
  bool get transient => this != changed && this != other;
}
