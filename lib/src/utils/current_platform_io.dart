import 'dart:io';

/// Whether the current platform follows Apple's keyboard conventions
/// (Meta = Cmd).
///
/// iOS can't actually run nocterm, but keeping the check preserves
/// semantic completeness.
bool get isApplePlatform => Platform.isMacOS || Platform.isIOS;
