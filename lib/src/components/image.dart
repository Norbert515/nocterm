import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/image/color_quantizer.dart';
import 'package:nocterm/src/image/image_cleanup.dart';
import 'package:nocterm/src/image/iterm2_encoder.dart';
import 'package:nocterm/src/image/kitty_encoder.dart';
import 'package:nocterm/src/image/sixel_encoder.dart';
import 'package:nocterm/src/image/unicode_block_encoder.dart';

/// Decoded image data in RGBA format.
///
/// This class holds the raw pixel data of a decoded image, ready for
/// processing into sixel format.
class ImageData {
  /// Creates image data from raw RGBA pixels.
  const ImageData({
    required this.pixels,
    required this.width,
    required this.height,
  });

  /// The raw RGBA pixel data.
  /// Each pixel is 4 bytes: red, green, blue, alpha.
  final Uint8List pixels;

  /// The width of the image in pixels.
  final int width;

  /// The height of the image in pixels.
  final int height;

  /// Creates a scaled version of this image.
  ///
  /// Uses simple nearest-neighbor scaling.
  ImageData scale(int newWidth, int newHeight) {
    if (newWidth == width && newHeight == height) {
      return this;
    }

    final scaledPixels = Uint8List(newWidth * newHeight * 4);

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        // Map to source coordinates
        final srcX = (x * width / newWidth).floor();
        final srcY = (y * height / newHeight).floor();

        final srcIndex = (srcY * width + srcX) * 4;
        final dstIndex = (y * newWidth + x) * 4;

        scaledPixels[dstIndex] = pixels[srcIndex];
        scaledPixels[dstIndex + 1] = pixels[srcIndex + 1];
        scaledPixels[dstIndex + 2] = pixels[srcIndex + 2];
        scaledPixels[dstIndex + 3] = pixels[srcIndex + 3];
      }
    }

    return ImageData(
      pixels: scaledPixels,
      width: newWidth,
      height: newHeight,
    );
  }
}

/// Base class for image providers.
///
/// Image providers are responsible for loading and decoding images from
/// various sources (files, network, memory).
///
/// This follows Flutter's ImageProvider pattern.
abstract class ImageProvider {
  /// Creates an image provider.
  const ImageProvider();

  /// Resolves this provider and returns the decoded image data.
  ///
  /// This method may be called multiple times, and implementations should
  /// cache results as appropriate.
  Future<ImageData> resolve();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

/// An image provider that loads an image from a file.
///
/// Example:
/// ```dart
/// Image(image: FileImage('/path/to/image.png'))
/// ```
class FileImage extends ImageProvider {
  /// Creates a file image provider.
  const FileImage(this.path);

  /// The path to the image file.
  final String path;

  @override
  Future<ImageData> resolve() async {
    final file = io.File(path);
    if (!await file.exists()) {
      throw Exception('Image file not found: $path');
    }

    final bytes = await file.readAsBytes();
    return _decodeImage(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileImage && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}

/// An image provider that loads an image from a URL.
///
/// Example:
/// ```dart
/// Image(image: NetworkImage('https://example.com/image.png'))
/// ```
class NetworkImage extends ImageProvider {
  /// Creates a network image provider.
  const NetworkImage(this.url);

  /// The URL of the image.
  final String url;

  @override
  Future<ImageData> resolve() async {
    final uri = Uri.parse(url);
    final client = io.HttpClient();

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );

      return _decodeImage(Uint8List.fromList(bytes));
    } finally {
      client.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

/// An image provider that uses in-memory image bytes.
///
/// Example:
/// ```dart
/// final bytes = await loadImageBytes();
/// Image(image: MemoryImage(bytes))
/// ```
class MemoryImage extends ImageProvider {
  /// Creates a memory image provider.
  const MemoryImage(this.bytes);

  /// The image bytes.
  final Uint8List bytes;

  @override
  Future<ImageData> resolve() async {
    return _decodeImage(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MemoryImage) return false;
    if (other.bytes.length != bytes.length) return false;
    // Compare first few bytes for identity
    for (int i = 0; i < bytes.length && i < 32; i++) {
      if (other.bytes[i] != bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(bytes.length, bytes.isNotEmpty ? bytes[0] : 0);
}

/// Decodes image bytes into RGBA pixel data.
///
/// Supports PNG, JPEG, GIF, BMP, WebP, and other common formats via the `image` package.
ImageData _decodeImage(Uint8List bytes) {
  // Use the image package to decode
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    // Failed to decode - return placeholder
    return _createPlaceholder(64, 64);
  }

  // Convert to RGBA pixel data
  final width = decoded.width;
  final height = decoded.height;
  final pixels = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = decoded.getPixel(x, y);
      final index = (y * width + x) * 4;

      pixels[index] = pixel.r.toInt();
      pixels[index + 1] = pixel.g.toInt();
      pixels[index + 2] = pixel.b.toInt();
      pixels[index + 3] = pixel.a.toInt();
    }
  }

  return ImageData(pixels: pixels, width: width, height: height);
}

/// Creates a placeholder image with a checkerboard pattern.
ImageData _createPlaceholder(int width, int height) {
  final pixels = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final index = (y * width + x) * 4;
      final isLight = ((x ~/ 8) + (y ~/ 8)) % 2 == 0;

      pixels[index] = isLight ? 200 : 100; // R
      pixels[index + 1] = isLight ? 200 : 100; // G
      pixels[index + 2] = isLight ? 200 : 100; // B
      pixels[index + 3] = 255; // A
    }
  }

  return ImageData(pixels: pixels, width: width, height: height);
}

/// How a box should be inscribed into another box.
///
/// This follows Flutter's BoxFit enum.
enum BoxFit {
  /// Fill the target box by distorting the source's aspect ratio.
  fill,

  /// As large as possible while still containing the source entirely within
  /// the target box.
  contain,

  /// As small as possible while still covering the entire target box.
  cover,

  /// Make sure the full width of the source is shown.
  fitWidth,

  /// Make sure the full height of the source is shown.
  fitHeight,

  /// Align the source within the target box (by default, centering) and
  /// discard any portions of the source that lie outside the box.
  none,
}

/// A widget that displays an image in the terminal.
///
/// {@template nocterm.image.experimental}
/// **Experimental**: This feature is experimental and requires terminal support
/// for image protocols. Not all terminals support image display.
///
/// ## Supported Terminals
///
/// | Terminal | Kitty | iTerm2 | Sixel | Unicode Blocks |
/// |----------|-------|--------|-------|----------------|
/// | **Kitty** | Yes | No | No | Fallback |
/// | **iTerm2** | No | Yes | No | Fallback |
/// | **WezTerm** | Yes | Yes | Yes | Fallback |
/// | **Ghostty** | Yes | No | No | Fallback |
/// | **Mintty** | No | No | Yes | Fallback |
/// | **mlterm** | No | No | Yes | Fallback |
/// | **xterm** (with sixel) | No | No | Yes | Fallback |
/// | **foot** | No | No | Yes | Fallback |
/// | **VS Code Terminal** | No | No | No | Fallback only |
/// | **macOS Terminal** | No | No | No | Fallback only |
/// | **GNOME Terminal** | No | No | No | Fallback only |
/// | **Windows Terminal** | No | No | No | Fallback only |
///
/// The Unicode blocks fallback works in all terminals but provides lower
/// resolution (2 pixels per character cell using half-block characters).
/// {@endtemplate}
///
/// ## Example
///
/// ```dart
/// // From a file
/// Image.file('/path/to/image.png')
///
/// // From a URL
/// Image.network('https://example.com/image.png')
///
/// // From memory
/// Image.memory(bytes)
///
/// // With options
/// Image(
///   image: FileImage('/path/to/image.png'),
///   width: 20,  // cells
///   height: 10, // cells
///   fit: BoxFit.contain,
///   protocol: ImageProtocol.kitty, // Force specific protocol
/// )
/// ```
///
/// ## Image Protocols
///
/// - [ImageProtocol.kitty]: Best quality, supported by Kitty, WezTerm, Ghostty
/// - [ImageProtocol.iterm2]: Supported by iTerm2 and WezTerm
/// - [ImageProtocol.sixel]: Older protocol, wide terminal support
/// - [ImageProtocol.unicodeBlocks]: Universal fallback using Unicode characters
///
/// If no protocol is specified, the best available protocol is auto-detected.
@experimental
class Image extends StatefulComponent {
  /// Creates an image widget.
  const Image({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.protocol,
  });

  /// Creates an image widget from a file path.
  Image.file(
    String path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.protocol,
  }) : image = FileImage(path);

  /// Creates an image widget from a URL.
  Image.network(
    String url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.protocol,
  }) : image = NetworkImage(url);

  /// Creates an image widget from bytes in memory.
  Image.memory(
    Uint8List bytes, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.protocol,
  }) : image = MemoryImage(bytes);

  /// The image to display.
  final ImageProvider image;

  /// The width of the image in cells.
  ///
  /// If null, the image will size itself based on the source image dimensions.
  final int? width;

  /// The height of the image in cells.
  ///
  /// If null, the image will size itself based on the source image dimensions.
  final int? height;

  /// How to inscribe the image into the space allocated during layout.
  final BoxFit fit;

  /// A widget to display while the image is loading.
  final Component? placeholder;

  /// A widget to display if the image fails to load.
  final Component? errorWidget;

  /// The image protocol to use.
  ///
  /// If null, the best available protocol will be auto-detected based on
  /// terminal capabilities.
  final ImageProtocol? protocol;

  @override
  State<Image> createState() => _ImageState();
}

class _ImageState extends State<Image> {
  ImageData? _imageData;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateComponent(Image oldComponent) {
    if (component.image != oldComponent.image) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await component.image.resolve();
      if (mounted) {
        setState(() {
          _imageData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Component build(BuildContext context) {
    if (_isLoading) {
      return component.placeholder ??
          SizedBox(
            width: component.width?.toDouble(),
            height: component.height?.toDouble(),
            child: const Text('...'),
          );
    }

    if (_error != null) {
      return component.errorWidget ??
          SizedBox(
            width: component.width?.toDouble(),
            height: component.height?.toDouble(),
            child: const Text('[!]'),
          );
    }

    return _RawImage(
      imageData: _imageData!,
      width: component.width,
      height: component.height,
      fit: component.fit,
      protocol: component.protocol,
    );
  }
}

/// Internal widget that renders the actual image.
class _RawImage extends SingleChildRenderObjectComponent {
  const _RawImage({
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.protocol,
  });

  final ImageData imageData;
  final int? width;
  final int? height;
  final BoxFit fit;
  final ImageProtocol? protocol;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderImage(
      imageData: imageData,
      requestedWidth: width,
      requestedHeight: height,
      fit: fit,
      protocol: protocol,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderImage renderObject) {
    renderObject
      ..imageData = imageData
      ..requestedWidth = width
      ..requestedHeight = height
      ..fit = fit
      ..protocol = protocol;
  }
}

/// A render object that displays an image using terminal graphics protocols.
///
/// Supports multiple protocols:
/// - **Kitty**: Native graphics protocol with image ID tracking for cleanup
/// - **Sixel**: Standard terminal graphics (default fallback)
/// - **iTerm2**: Inline images protocol
/// - **Unicode blocks**: Universal fallback using half-block characters
class RenderImage extends RenderObject {
  /// Creates a render image.
  RenderImage({
    required ImageData imageData,
    int? requestedWidth,
    int? requestedHeight,
    BoxFit fit = BoxFit.contain,
    ImageProtocol? protocol,
  })  : _imageData = imageData,
        _requestedWidth = requestedWidth,
        _requestedHeight = requestedHeight,
        _fit = fit,
        _protocol = protocol;

  /// Assumed pixels per cell (width x height).
  /// Common terminal defaults are 8x16 or 10x20.
  static const int cellPixelWidth = 8;
  static const int cellPixelHeight = 16;

  /// Cached detected protocol for the current terminal.
  /// This is lazily initialized on first use.
  static ImageProtocol? _detectedProtocol;

  ImageData _imageData;
  ImageData get imageData => _imageData;
  set imageData(ImageData value) {
    if (_imageData == value) return;
    _imageData = value;
    _cachedEncodedData = null;
    _cachedScaledImage = null;
    _cachedBlockCells = null;
    _kittyImageId = null; // Reset so new ID is generated on next paint
    markNeedsLayout();
  }

  int? _requestedWidth;
  int? get requestedWidth => _requestedWidth;
  set requestedWidth(int? value) {
    if (_requestedWidth == value) return;
    _requestedWidth = value;
    _cachedEncodedData = null;
    _cachedScaledImage = null;
    _cachedBlockCells = null;
    _kittyImageId = null; // Reset so new ID is generated on next paint
    markNeedsLayout();
  }

  int? _requestedHeight;
  int? get requestedHeight => _requestedHeight;
  set requestedHeight(int? value) {
    if (_requestedHeight == value) return;
    _requestedHeight = value;
    _cachedEncodedData = null;
    _cachedScaledImage = null;
    _cachedBlockCells = null;
    _kittyImageId = null; // Reset so new ID is generated on next paint
    markNeedsLayout();
  }

  BoxFit _fit;
  BoxFit get fit => _fit;
  set fit(BoxFit value) {
    if (_fit == value) return;
    _fit = value;
    _cachedEncodedData = null;
    _cachedScaledImage = null;
    _cachedBlockCells = null;
    _kittyImageId = null; // Reset so new ID is generated on next paint
    markNeedsLayout();
  }

  ImageProtocol? _protocol;
  ImageProtocol? get protocol => _protocol;
  set protocol(ImageProtocol? value) {
    if (_protocol == value) return;
    _protocol = value;
    _cachedEncodedData = null;
    _cachedScaledImage = null;
    _cachedBlockCells = null;
    _kittyImageId = null; // Reset Kitty image ID when protocol changes
    markNeedsLayout();
  }

  // Cached encoded data string to avoid re-encoding on every paint
  String? _cachedEncodedData;
  ImageData? _cachedScaledImage;
  int? _cachedLayoutWidth;
  int? _cachedLayoutHeight;

  // Image cleanup registration
  ImageRegistration? _imageRegistration;
  int? _lastPaintX;
  int? _lastPaintY;
  int? _lastRegisteredKittyId; // Track registered ID to detect changes

  // Kitty protocol specific: unique image ID for cleanup
  int? _kittyImageId;

  @override
  void performLayout() {
    // Calculate the image's aspect ratio in cells
    final imageWidthInCells = (_imageData.width / cellPixelWidth).ceil();
    final imageHeightInCells = (_imageData.height / cellPixelHeight).ceil();
    final imageAspectRatio = imageWidthInCells / imageHeightInCells;

    // Determine target size
    double targetWidth;
    double targetHeight;

    if (_requestedWidth != null && _requestedHeight != null) {
      // Both specified - use them directly
      targetWidth = _requestedWidth!.toDouble();
      targetHeight = _requestedHeight!.toDouble();
    } else if (_requestedWidth != null) {
      // Width specified - calculate height from aspect ratio
      targetWidth = _requestedWidth!.toDouble();
      targetHeight = targetWidth / imageAspectRatio;
    } else if (_requestedHeight != null) {
      // Height specified - calculate width from aspect ratio
      targetHeight = _requestedHeight!.toDouble();
      targetWidth = targetHeight * imageAspectRatio;
    } else {
      // No size specified - fit within constraints while preserving aspect ratio
      // If constraints are unbounded, we can't properly size the image yet.
      // This can happen on the first frame before parent layout propagates.
      if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
        // No bounded constraints at all - use minimal size and schedule relayout
        size = constraints.constrain(const Size(1, 1));
        // Schedule a relayout for next frame when constraints should be ready
        SchedulerBinding.instance.addPostFrameCallback((_) {
          markNeedsLayout();
        });
        return;
      }

      // Use the smaller of the two possible sizes to ensure we fit in BOTH dimensions
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : imageWidthInCells.toDouble();
      final maxHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : imageHeightInCells.toDouble();

      // Calculate what size we'd get if constrained by width vs height
      final widthFromHeight = maxHeight * imageAspectRatio;
      final heightFromWidth = maxWidth / imageAspectRatio;

      // Choose the smaller size that fits within BOTH constraints
      if (widthFromHeight <= maxWidth) {
        // Height is the limiting factor
        targetWidth = widthFromHeight;
        targetHeight = maxHeight;
      } else {
        // Width is the limiting factor
        targetWidth = maxWidth;
        targetHeight = heightFromWidth;
      }

      // Ensure we respect minimum constraints (grow if needed)
      if (targetWidth < constraints.minWidth) {
        targetWidth = constraints.minWidth;
        targetHeight = targetWidth / imageAspectRatio;
      }
      if (targetHeight < constraints.minHeight) {
        targetHeight = constraints.minHeight;
        targetWidth = targetHeight * imageAspectRatio;
      }
    }

    // Apply constraints
    size = constraints.constrain(Size(targetWidth, targetHeight));

    // Invalidate cache if size changed
    if (_cachedLayoutWidth != size.width.toInt() ||
        _cachedLayoutHeight != size.height.toInt()) {
      _cachedEncodedData = null;
      _cachedScaledImage = null;
      _cachedBlockCells = null;
      _kittyImageId =
          null; // Reset to generate new image with correct dimensions
      _cachedLayoutWidth = size.width.toInt();
      _cachedLayoutHeight = size.height.toInt();
    }
  }

  // Cached palette and indexed pixels for sixel encoding
  List<Color>? _cachedPalette;
  Uint8List? _cachedIndexedPixels;

  // Cached block cells for unicode blocks rendering
  List<List<BlockCell>>? _cachedBlockCells;

  /// Detect the best available protocol based on terminal capabilities.
  ///
  /// Priority order:
  /// 1. Kitty (best quality, native cleanup support)
  /// 2. Sixel (widely supported)
  /// 3. iTerm2 (macOS terminals)
  /// 4. Unicode blocks (universal fallback)
  static ImageProtocol _detectProtocol() {
    if (_detectedProtocol != null) {
      return _detectedProtocol!;
    }

    final term = io.Platform.environment['TERM']?.toLowerCase() ?? '';
    final termProgram =
        io.Platform.environment['TERM_PROGRAM']?.toLowerCase() ?? '';

    // Check for Kitty terminal
    if (term.contains('kitty') ||
        io.Platform.environment.containsKey('KITTY_WINDOW_ID')) {
      _detectedProtocol = ImageProtocol.kitty;
      return _detectedProtocol!;
    }

    // Check for WezTerm (supports Kitty protocol)
    if (termProgram.contains('wezterm') || term.contains('wezterm')) {
      _detectedProtocol = ImageProtocol.kitty;
      return _detectedProtocol!;
    }

    // Check for iTerm2
    if (termProgram.contains('iterm') ||
        io.Platform.environment.containsKey('ITERM_SESSION_ID')) {
      _detectedProtocol = ImageProtocol.iterm2;
      return _detectedProtocol!;
    }

    // Check for known Sixel-supporting terminals
    const sixelTerms = ['xterm', 'mlterm', 'yaft', 'foot', 'contour', 'mintty'];
    for (final sixelTerm in sixelTerms) {
      if (term.contains(sixelTerm)) {
        _detectedProtocol = ImageProtocol.sixel;
        return _detectedProtocol!;
      }
    }

    // Default to unicode blocks (universal fallback)
    _detectedProtocol = ImageProtocol.unicodeBlocks;
    return _detectedProtocol!;
  }

  /// Get the effective protocol (user-specified or auto-detected).
  ImageProtocol get _effectiveProtocol => _protocol ?? _detectProtocol();

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    // Don't paint if we haven't been properly laid out yet
    if (size.width <= 1 || size.height <= 1) {
      return;
    }

    final effectiveProtocol = _effectiveProtocol;

    // Calculate pixel dimensions for the target cell size
    final targetPixelWidth = size.width.toInt() * cellPixelWidth;
    final targetPixelHeight = size.height.toInt() * cellPixelHeight;

    // Scale image if needed
    if (_cachedScaledImage == null) {
      _cachedScaledImage = _scaleImageForFit(
        _imageData,
        targetPixelWidth,
        targetPixelHeight,
        _fit,
      );
      // Invalidate dependent caches
      _cachedPalette = null;
      _cachedIndexedPixels = null;
      _cachedEncodedData = null;
    }

    final x = offset.dx.toInt();
    final y = offset.dy.toInt();
    final w = size.width.toInt();
    final h = size.height.toInt();

    // Handle Unicode blocks differently - render cell by cell
    if (effectiveProtocol == ImageProtocol.unicodeBlocks) {
      _paintUnicodeBlocks(canvas, offset);
      return;
    }

    // For other protocols, encode and use drawImage
    _cachedEncodedData ??= _encodeForProtocol(effectiveProtocol);

    // Register/update image for cleanup tracking
    // Re-register if position changed, no registration exists, or kittyImageId changed
    final needsReregistration = _lastPaintX != x ||
        _lastPaintY != y ||
        _imageRegistration == null ||
        _lastRegisteredKittyId != _kittyImageId;

    if (needsReregistration) {
      // Dispose old registration to trigger cleanup of old image
      _imageRegistration?.dispose();
      _imageRegistration = ImageCleanupManager.instance.registerImage(
        x: x,
        y: y,
        width: w,
        height: h,
        protocol: effectiveProtocol,
        kittyImageId: _kittyImageId,
      );
      _lastPaintX = x;
      _lastPaintY = y;
      _lastRegisteredKittyId = _kittyImageId;
    }

    // Draw the image using protocol-specific escape sequences
    canvas.drawImage(
      _cachedScaledImage!,
      _cachedEncodedData!,
      x,
      y,
      w,
      h,
    );
  }

  /// Paint using Unicode block characters cell-by-cell.
  void _paintUnicodeBlocks(TerminalCanvas canvas, Offset offset) {
    // For Unicode blocks: 1 pixel = 1 cell width, 2 pixels = 1 cell height
    // So we need to scale the image to: width = cell width, height = cell height * 2
    final targetWidth = size.width.toInt();
    final targetHeight = size.height.toInt() * 2; // 2 pixels per cell height

    // Encode to block cells if needed (using properly scaled image for unicode)
    if (_cachedBlockCells == null) {
      // Scale the original image for unicode block rendering
      final scaledForUnicode = _imageData.scale(targetWidth, targetHeight);

      const encoder = UnicodeBlockEncoder();
      _cachedBlockCells = encoder.encode(
        pixels: scaledForUnicode.pixels,
        width: scaledForUnicode.width,
        height: scaledForUnicode.height,
      );
    }

    final blockCells = _cachedBlockCells!;

    // Draw each cell individually using canvas.drawText
    for (int row = 0;
        row < blockCells.length && row < size.height.toInt();
        row++) {
      final rowCells = blockCells[row];
      for (int col = 0;
          col < rowCells.length && col < size.width.toInt();
          col++) {
        final cell = rowCells[col];

        // Create style from block cell colors
        final style = TextStyle(
          color: cell.foreground.isDefault ? null : cell.foreground,
          backgroundColor: cell.background.isDefault ? null : cell.background,
        );

        // Draw the single character at the correct position
        canvas.drawText(
          Offset(offset.dx + col, offset.dy + row),
          cell.char,
          style: style,
        );
      }
    }
  }

  /// Encode the scaled image for the specified protocol.
  String _encodeForProtocol(ImageProtocol protocol) {
    final scaledImage = _cachedScaledImage!;

    switch (protocol) {
      case ImageProtocol.kitty:
        // Generate a unique Kitty image ID for cleanup tracking
        // Use original full-resolution image for best quality
        // Kitty will scale it down to the specified cell dimensions
        _kittyImageId = KittyEncoder.getNextImageId();
        return KittyEncoder.encodeRgba(
          rgbaPixels: _imageData.pixels,
          width: _imageData.width,
          height: _imageData.height,
          imageId: _kittyImageId,
          displayColumns: size.width.toInt(),
          displayRows: size.height.toInt(),
        );

      case ImageProtocol.sixel:
        // Quantize colors for Sixel (requires palette)
        if (_cachedPalette == null || _cachedIndexedPixels == null) {
          final (palette, indexedPixels) = ColorQuantizer.quantize(
            rgbaPixels: scaledImage.pixels,
            width: scaledImage.width,
            height: scaledImage.height,
            maxColors: 256,
          );
          _cachedPalette = palette;
          _cachedIndexedPixels = indexedPixels;
        }
        return SixelEncoder.encode(
          pixels: scaledImage.pixels,
          width: scaledImage.width,
          height: scaledImage.height,
          palette: _cachedPalette!,
          indexedPixels: _cachedIndexedPixels!,
        );

      case ImageProtocol.iterm2:
        // Use original full-resolution image for best quality
        // iTerm2 will scale it down to the specified cell dimensions
        return ITerm2Encoder.encodeRgba(
          rgbaPixels: _imageData.pixels,
          width: _imageData.width,
          height: _imageData.height,
          displayWidth: '${size.width.toInt()}',
          displayHeight: '${size.height.toInt()}',
        );

      case ImageProtocol.unicodeBlocks:
        // Unicode blocks are handled separately in _paintUnicodeBlocks
        // This should not be called for unicode blocks
        return '';
    }
  }

  @override
  void dispose() {
    // Clean up the image when this render object is disposed
    _imageRegistration?.dispose();
    _imageRegistration = null;
    super.dispose();
  }

  /// Scale the image according to the BoxFit mode.
  ImageData _scaleImageForFit(
    ImageData source,
    int targetWidth,
    int targetHeight,
    BoxFit fit,
  ) {
    final sourceAspect = source.width / source.height;
    final targetAspect = targetWidth / targetHeight;

    int scaledWidth;
    int scaledHeight;

    switch (fit) {
      case BoxFit.fill:
        scaledWidth = targetWidth;
        scaledHeight = targetHeight;
        break;

      case BoxFit.contain:
        if (sourceAspect > targetAspect) {
          scaledWidth = targetWidth;
          scaledHeight = (targetWidth / sourceAspect).round();
        } else {
          scaledHeight = targetHeight;
          scaledWidth = (targetHeight * sourceAspect).round();
        }
        break;

      case BoxFit.cover:
        if (sourceAspect > targetAspect) {
          scaledHeight = targetHeight;
          scaledWidth = (targetHeight * sourceAspect).round();
        } else {
          scaledWidth = targetWidth;
          scaledHeight = (targetWidth / sourceAspect).round();
        }
        break;

      case BoxFit.fitWidth:
        scaledWidth = targetWidth;
        scaledHeight = (targetWidth / sourceAspect).round();
        break;

      case BoxFit.fitHeight:
        scaledHeight = targetHeight;
        scaledWidth = (targetHeight * sourceAspect).round();
        break;

      case BoxFit.none:
        scaledWidth = source.width;
        scaledHeight = source.height;
        break;
    }

    // Ensure minimum size
    scaledWidth = scaledWidth.clamp(1, targetWidth * 2);
    scaledHeight = scaledHeight.clamp(1, targetHeight * 2);

    return source.scale(scaledWidth, scaledHeight);
  }
}
