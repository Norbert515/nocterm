/// Stub for web builds where `dart:io` is unavailable.
///
/// Defaults to `false` so the Meta+A/C/V/X clipboard aliases are NOT
/// enabled on web. On web terminals the browser environment parses Cmd
/// into Meta too, but aliases stay disabled by default there for now —
/// see the review discussion on upstream PR #92.
bool get isApplePlatform => false;
