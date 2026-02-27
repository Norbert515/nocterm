import 'package:nocterm/src/image/kitty_encoder.dart';

/// Available image display protocols.
enum ImageProtocol {
  /// Unicode half-block characters (universal fallback).
  unicodeBlocks,

  /// iTerm2 inline images protocol.
  iterm2,

  /// Sixel graphics protocol.
  sixel,

  /// Kitty graphics protocol.
  kitty,
}

/// Callback type for writing escape sequences to the terminal.
typedef TerminalWriter = void Function(String data);

/// Manages cleanup of terminal images when components are unmounted.
///
/// This class handles the complexity of cleaning up images across different
/// terminal graphics protocols:
///
/// - **Kitty**: Uses native delete commands with image IDs
/// - **Sixel/iTerm2**: Overwrites image region with spaces (scheduled for next frame)
/// - **Unicode blocks**: No cleanup needed (cells are just overwritten)
///
/// Usage:
/// ```dart
/// // When rendering an image, register it:
/// final registration = ImageCleanupManager.instance.registerImage(
///   x: 0, y: 0, width: 10, height: 5,
///   protocol: ImageProtocol.kitty,
///   kittyImageId: 42,
/// );
///
/// // When disposing the image render object:
/// registration.dispose();
/// ```
class ImageCleanupManager {
  ImageCleanupManager._();

  static final ImageCleanupManager instance = ImageCleanupManager._();

  /// Terminal writer callback (set by the binding).
  TerminalWriter? _terminalWriter;

  /// Pending regions that need to be cleared with spaces.
  /// These are processed during the next frame.
  final List<ImageRegion> _pendingCleanups = [];

  /// Whether any Kitty images were registered during this app session.
  bool _hasKittyImages = false;

  /// Set the terminal writer callback.
  ///
  /// This should be called by the binding during initialization.
  void setTerminalWriter(TerminalWriter writer) {
    _terminalWriter = writer;
  }

  /// Register an image for cleanup tracking.
  ///
  /// Returns an [ImageRegistration] that should be disposed when the
  /// image component is unmounted.
  ImageRegistration registerImage({
    required int x,
    required int y,
    required int width,
    required int height,
    required ImageProtocol protocol,
    int? kittyImageId,
  }) {
    if (protocol == ImageProtocol.kitty && kittyImageId != null) {
      _hasKittyImages = true;
    }

    return ImageRegistration._(
      manager: this,
      region: ImageRegion(x: x, y: y, width: width, height: height),
      protocol: protocol,
      kittyImageId: kittyImageId,
    );
  }

  /// Get pending cleanup regions and clear the list.
  ///
  /// Called by the terminal binding during rendering to get regions
  /// that need to be overwritten with spaces.
  List<ImageRegion> consumePendingCleanups() {
    final regions = List<ImageRegion>.from(_pendingCleanups);
    _pendingCleanups.clear();
    return regions;
  }

  /// Check if there are pending cleanups.
  bool get hasPendingCleanups => _pendingCleanups.isNotEmpty;

  void _cleanupKitty(int imageId) {
    final writer = _terminalWriter;
    if (writer != null) {
      writer(KittyEncoder.delete(imageId: imageId));
    }
  }

  void _scheduleSpaceCleanup(ImageRegion region) {
    _pendingCleanups.add(region);
  }

  /// Clear all images from the terminal.
  ///
  /// This should be called during shutdown to ensure no images are left
  /// on the screen when the TUI exits.
  void clearAllImages() {
    final writer = _terminalWriter;
    if (writer != null && _hasKittyImages) {
      // Delete all Kitty images (no image ID = delete all)
      writer(KittyEncoder.delete());
    }
    _hasKittyImages = false;
    // Clear any pending cleanups since we're shutting down
    _pendingCleanups.clear();
  }
}

/// Represents a registered image that will be cleaned up on dispose.
class ImageRegistration {
  ImageRegistration._({
    required ImageCleanupManager manager,
    required this.region,
    required this.protocol,
    this.kittyImageId,
  }) : _manager = manager;

  final ImageCleanupManager _manager;
  final ImageRegion region;
  final ImageProtocol protocol;
  final int? kittyImageId;

  bool _disposed = false;

  /// Update the image region (e.g., if it moved or resized).
  ImageRegistration updateRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    // For Kitty, we don't need to do anything special on move
    // The new registration will handle cleanup
    return ImageRegistration._(
      manager: _manager,
      region: ImageRegion(x: x, y: y, width: width, height: height),
      protocol: protocol,
      kittyImageId: kittyImageId,
    );
  }

  /// Dispose this registration, triggering cleanup.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    switch (protocol) {
      case ImageProtocol.kitty:
        if (kittyImageId != null) {
          _manager._cleanupKitty(kittyImageId!);
        }
        break;

      case ImageProtocol.sixel:
      case ImageProtocol.iterm2:
        // Schedule space overwrite for next frame
        _manager._scheduleSpaceCleanup(region);
        break;

      case ImageProtocol.unicodeBlocks:
        // Unicode blocks are just text cells, they get overwritten naturally
        break;
    }
  }
}

/// Represents a rectangular region on the terminal.
class ImageRegion {
  final int x;
  final int y;
  final int width;
  final int height;

  const ImageRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'ImageRegion($x, $y, ${width}x$height)';
}
