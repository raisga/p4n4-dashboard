/// What an `<iframe>`'s load event says about the page in it.
enum FrameLoad {
  /// A page from this origin loaded, and the app can read it.
  shown,

  /// A page from this origin that the browser wouldn't show in a frame (its
  /// `X-Frame-Options` or `frame-ancestors`): the frame holds the browser's
  /// error page instead, which the app can't read.
  blocked,

  /// A page from another origin, or the browser's error page in its place:
  /// browsers don't say which, so a refused page just looks blank.
  opaque,
}
