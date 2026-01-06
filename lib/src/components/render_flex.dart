import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// Render object for flex layouts (Row/Column)
class RenderFlex extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  /// Whether to show overflow indicators in debug mode
  static bool debugShowOverflowIndicator = true;

  RenderFlex({
    required Axis direction,
    required MainAxisAlignment mainAxisAlignment,
    required MainAxisSize mainAxisSize,
    required CrossAxisAlignment crossAxisAlignment,
    required TextDirection textDirection,
    required VerticalDirection verticalDirection,
    TextBaseline? textBaseline,
  }) : _direction = direction,
       _mainAxisAlignment = mainAxisAlignment,
       _mainAxisSize = mainAxisSize,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection,
       _verticalDirection = verticalDirection,
       _textBaseline = textBaseline;

  /// Set during layout if overflow occurred on the main axis.
  double _overflow = 0;

  /// Check whether any meaningful overflow is present.
  bool get hasOverflow =>
      _overflow > 0.01; // Small epsilon for floating point errors

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = FlexParentData();
    }
  }

  Axis _direction;
  Axis get direction => _direction;
  set direction(Axis value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  MainAxisAlignment _mainAxisAlignment;
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    if (_mainAxisAlignment == value) return;
    _mainAxisAlignment = value;
    markNeedsLayout();
  }

  MainAxisSize _mainAxisSize;
  MainAxisSize get mainAxisSize => _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    if (_mainAxisSize == value) return;
    _mainAxisSize = value;
    markNeedsLayout();
  }

  CrossAxisAlignment _crossAxisAlignment;
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  VerticalDirection _verticalDirection;
  VerticalDirection get verticalDirection => _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection == value) return;
    _verticalDirection = value;
    markNeedsLayout();
  }

  TextBaseline? _textBaseline;
  TextBaseline? get textBaseline => _textBaseline;
  set textBaseline(TextBaseline? value) {
    if (_textBaseline == value) return;
    _textBaseline = value;
    markNeedsLayout();
  }

  double _getMainAxisExtent(Size size) {
    return direction == Axis.horizontal ? size.width : size.height;
  }

  double _getCrossAxisExtent(Size size) {
    return direction == Axis.horizontal ? size.height : size.width;
  }

  Size _getSize(double mainAxisExtent, double crossAxisExtent) {
    return direction == Axis.horizontal
        ? Size(mainAxisExtent, crossAxisExtent)
        : Size(crossAxisExtent, mainAxisExtent);
  }

  int _getFlex(RenderObject child) {
    final FlexParentData parentData = child.parentData as FlexParentData;
    return parentData.flex ?? 0;
  }

  FlexFit _getFlexFit(RenderObject child) {
    final FlexParentData parentData = child.parentData as FlexParentData;
    return parentData.fit ?? FlexFit.tight;
  }

  bool _hasFlexChildren() {
    for (final child in children) {
      if (_getFlex(child) > 0) {
        return true;
      }
    }
    return false;
  }

  BoxConstraints _getChildConstraints(
    BoxConstraints constraints,
    double? maxMainAxisExtent,
  ) {
    // For non-flex children (when maxMainAxisExtent is null), pass infinite constraint along the main axis
    // This matches Flutter's behavior in _constraintsForNonFlexChild

    // When CrossAxisAlignment.stretch is used, children should get tight constraints on the cross axis
    final bool shouldStretch = crossAxisAlignment == CrossAxisAlignment.stretch;

    BoxConstraints result;
    if (direction == Axis.horizontal) {
      // For Row: width is main axis, height is cross axis
      result = BoxConstraints(
        minWidth: 0,
        maxWidth:
            maxMainAxisExtent ??
            double.infinity, // Pass infinity for non-flex children
        minHeight: shouldStretch ? constraints.maxHeight : 0,
        maxHeight: constraints.maxHeight,
      );
    } else {
      // For Column: height is main axis, width is cross axis
      result = BoxConstraints(
        minWidth: shouldStretch ? constraints.maxWidth : 0,
        maxWidth: constraints.maxWidth,
        minHeight: 0,
        maxHeight:
            maxMainAxisExtent ??
            double.infinity, // Pass infinity for non-flex children
      );
    }

    // Debug: log constraints for stretch
    // if (shouldStretch && direction == Axis.vertical) {
    //   print('Column stretch: incoming=$constraints');
    //   print('  Child constraints: minW=${result.minWidth}, maxW=${result.maxWidth}, minH=${result.minHeight}, maxH=${result.maxHeight}');
    // }

    return result;
  }

  @override
  void performLayout() {
    // Two-pass flex layout algorithm
    int totalFlex = 0;
    double allocatedSize = 0;
    double maxCrossAxisExtent = 0;
    final double maxMainAxisExtent = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final bool canFlex = maxMainAxisExtent.isFinite;

    // Check for invalid flex usage with unbounded constraints
    // This matches Flutter's behavior - only error when there are flex children
    if (!canFlex && (mainAxisSize == MainAxisSize.max || _hasFlexChildren())) {
      // Check if we actually have flex children that would cause issues
      bool hasProblematicFlexChild = false;
      for (final child in children) {
        final int flex = _getFlex(child);
        if (flex > 0 &&
            (mainAxisSize == MainAxisSize.max ||
                _getFlexFit(child) == FlexFit.tight)) {
          hasProblematicFlexChild = true;
          break;
        }
      }

      if (hasProblematicFlexChild) {
        final String identity = direction == Axis.horizontal ? 'Row' : 'Column';
        final String axis = direction == Axis.horizontal
            ? 'horizontal'
            : 'vertical';
        final String dimension = direction == Axis.horizontal
            ? 'width'
            : 'height';

        throw FlutterError(
          'RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.\n'
          'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
          'if it is in a $axis scrollable or another $identity, it will try to shrink-wrap its children along the $axis '
          'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
          'expand to fill the remaining space in the $axis direction.\n'
          'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
          'cannot simultaneously expand to fit its parent.\n'
          'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
          'children (using Flexible rather than Expanded). This will allow the flexible children '
          'to size themselves to less than the infinite remaining space they would otherwise be '
          'forced to take, and then will cause the RenderFlex to shrink-wrap the children '
          'rather than expanding to fit the maximum constraints provided by the parent.\n'
          'The affected RenderFlex is: $this\n'
          'See also: https://flutter.dev/unbounded-constraints',
        );
      }
    }

    // First pass: layout non-flexible children and count total flex
    for (final child in children) {
      final int flex = _getFlex(child);
      if (flex > 0) {
        totalFlex += flex;
      } else {
        // Layout non-flexible children
        final childConstraints = _getChildConstraints(constraints, null);
        child.layout(childConstraints, parentUsesSize: true);
        final childSize = child.size;
        allocatedSize += _getMainAxisExtent(childSize);
        maxCrossAxisExtent = math.max(
          maxCrossAxisExtent,
          _getCrossAxisExtent(childSize),
        );
      }
    }

    // Second pass: layout flexible children with remaining space
    if (totalFlex > 0) {
      if (!canFlex) {
        // If we get here, we have flexible children but unbounded constraints
        // This should have been caught above, but handle gracefully
        // Layout flex children with their natural size
        for (final child in children) {
          final int flex = _getFlex(child);
          if (flex > 0) {
            final childConstraints = _getChildConstraints(constraints, null);
            child.layout(childConstraints, parentUsesSize: true);
            final childSize = child.size;
            allocatedSize += _getMainAxisExtent(childSize);
            maxCrossAxisExtent = math.max(
              maxCrossAxisExtent,
              _getCrossAxisExtent(childSize),
            );
          }
        }
      } else {
        final double freeSpace = math.max(
          0.0,
          maxMainAxisExtent - allocatedSize,
        );
        final double spacePerFlex = freeSpace / totalFlex;

        for (final child in children) {
          final int flex = _getFlex(child);
          if (flex > 0) {
            final double maxChildExtent = spacePerFlex * flex;
            final FlexFit fit = _getFlexFit(child);

            // Create constraints for flex child
            final BoxConstraints childConstraints;
            if (direction == Axis.horizontal) {
              childConstraints = BoxConstraints(
                minWidth: fit == FlexFit.tight ? maxChildExtent : 0.0,
                maxWidth: maxChildExtent,
                minHeight: 0.0,
                maxHeight: constraints.maxHeight,
              );
            } else {
              childConstraints = BoxConstraints(
                minWidth: 0.0,
                maxWidth: constraints.maxWidth,
                minHeight: fit == FlexFit.tight ? maxChildExtent : 0.0,
                maxHeight: maxChildExtent,
              );
            }

            child.layout(childConstraints, parentUsesSize: true);
            final childSize = child.size;
            maxCrossAxisExtent = math.max(
              maxCrossAxisExtent,
              _getCrossAxisExtent(childSize),
            );
          }
        }
      }
    }

    // Calculate final size
    double mainAxisExtent;
    double crossAxisExtent;

    // Calculate actual used space including flex children
    double actualAllocatedSize = 0;
    for (final child in children) {
      actualAllocatedSize += _getMainAxisExtent(child.size);
    }

    // Handle MainAxisSize - support shrink-wrap behavior with MainAxisSize.min
    if (mainAxisSize == MainAxisSize.max && maxMainAxisExtent.isFinite) {
      mainAxisExtent = maxMainAxisExtent;
    } else {
      mainAxisExtent = actualAllocatedSize;
    }

    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      crossAxisExtent = direction == Axis.horizontal
          ? constraints.maxHeight
          : constraints.maxWidth;
    } else {
      crossAxisExtent = maxCrossAxisExtent;
    }

    size = constraints.constrain(_getSize(mainAxisExtent, crossAxisExtent));

    // Calculate overflow
    _overflow = actualAllocatedSize - mainAxisExtent;
    if (_overflow > 0 && debugShowOverflowIndicator) {
      // Log overflow warning with more details
      final axis = direction == Axis.horizontal ? "horizontal" : "vertical";
      final timestamp = DateTime.now().toIso8601String();
      print(
        '[$timestamp] ⚠️  RenderFlex overflowed by ${_overflow.toStringAsFixed(1)} pixels on the $axis axis.',
      );
      print('  Available space: ${mainAxisExtent.toStringAsFixed(1)} pixels');
      print(
        '  Required space: ${actualAllocatedSize.toStringAsFixed(1)} pixels',
      );
      print('  Number of children: ${children.length}');
    }

    // Position children and store in parent data
    final double freeSpace = math.max(
      0.0,
      mainAxisExtent - actualAllocatedSize,
    );

    // Calculate starting position based on alignment
    double mainAxisOffset = 0;
    double betweenSpace = 0;

    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        mainAxisOffset = 0;
        break;
      case MainAxisAlignment.end:
        mainAxisOffset = freeSpace;
        break;
      case MainAxisAlignment.center:
        mainAxisOffset = freeSpace / 2;
        break;
      case MainAxisAlignment.spaceBetween:
        if (children.length > 1) {
          betweenSpace = freeSpace / (children.length - 1);
        }
        break;
      case MainAxisAlignment.spaceAround:
        if (children.isNotEmpty) {
          betweenSpace = freeSpace / children.length;
          mainAxisOffset = betweenSpace / 2;
        }
        break;
      case MainAxisAlignment.spaceEvenly:
        if (children.isNotEmpty) {
          betweenSpace = freeSpace / (children.length + 1);
          mainAxisOffset = betweenSpace;
        }
        break;
    }

    // Position each child and store offset in parent data
    for (final child in children) {
      // Calculate cross axis offset based on alignment
      double crossAxisOffset = 0;
      final double childCrossExtent = _getCrossAxisExtent(child.size);
      final double availableCrossExtent = _getCrossAxisExtent(size);

      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
          crossAxisOffset = 0;
          break;
        case CrossAxisAlignment.end:
          crossAxisOffset = availableCrossExtent - childCrossExtent;
          break;
        case CrossAxisAlignment.center:
          crossAxisOffset = (availableCrossExtent - childCrossExtent) / 2;
          break;
        case CrossAxisAlignment.stretch:
        case CrossAxisAlignment.baseline:
          // For stretch, children should already be sized to fill
          // For baseline, we'd need baseline information (not implemented yet)
          crossAxisOffset = 0;
          break;
      }

      // Store position in parent data
      final FlexParentData childParentData = child.parentData as FlexParentData;
      childParentData.offset = direction == Axis.horizontal
          ? Offset(mainAxisOffset, crossAxisOffset)
          : Offset(crossAxisOffset, mainAxisOffset);

      mainAxisOffset += _getMainAxisExtent(child.size) + betweenSpace;
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    // Paint each child using the pre-calculated positions from performLayout
    for (final child in children) {
      final FlexParentData childParentData = child.parentData as FlexParentData;
      child.paintWithContext(canvas, offset + childParentData.offset);
    }

    // Paint overflow indicator if needed
    if (hasOverflow && debugShowOverflowIndicator) {
      _paintOverflowIndicator(canvas, offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    // Test children in reverse order (last child first, like paint order)
    for (final child in children.reversed) {
      final FlexParentData childParentData = child.parentData as FlexParentData;
      final childPosition = position - childParentData.offset;
      if (child.hitTest(result, position: childPosition)) {
        return true;
      }
    }
    return false;
  }

  void _paintOverflowIndicator(TerminalCanvas canvas, Offset offset) {
    // Create a checkerboard pattern for overflow area
    final overflowPattern = ['▒', '░'];
    final overflowStyle = TextStyle(
      color: Colors.brightRed,
      backgroundColor: Color.fromRGB(100, 0, 0), // Dark red background
    );

    if (direction == Axis.horizontal) {
      // Horizontal overflow - paint indicator on the right edge
      final indicatorWidth = math.max(2.0, math.min(_overflow, 3.0));
      final indicatorRect = Rect.fromLTWH(
        size.width - indicatorWidth.round(),
        0,
        indicatorWidth,
        size.height,
      );

      // Draw checkerboard pattern
      for (int y = 0; y < indicatorRect.height; y++) {
        for (int x = 0; x < indicatorRect.width; x++) {
          final patternIndex = (x + y) % 2;
          canvas.drawText(
            offset + Offset(indicatorRect.left + x, indicatorRect.top + y),
            overflowPattern[patternIndex],
            style: overflowStyle,
          );
        }
      }

      // Draw overflow amount text in the center of the indicator
      final overflowText = '${_overflow.toStringAsFixed(0)}px';
      if (indicatorRect.height >= 1 &&
          indicatorRect.width >= overflowText.length) {
        final textY = (indicatorRect.height / 2).floor().toDouble();
        final textX =
            indicatorRect.left +
            (indicatorRect.width - overflowText.length) / 2;
        canvas.drawText(
          offset + Offset(textX, textY),
          overflowText,
          style: TextStyle(
            color: Colors.brightWhite,
            backgroundColor: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      // Vertical overflow - paint indicator on the bottom edge
      final indicatorHeight = math.max(1.0, math.min(_overflow, 3.0));
      final indicatorRect = Rect.fromLTWH(
        0,
        size.height - indicatorHeight.round(),
        size.width,
        indicatorHeight,
      );

      // Draw checkerboard pattern
      for (int y = 0; y < indicatorRect.height; y++) {
        for (int x = 0; x < indicatorRect.width; x++) {
          final patternIndex = (x + y) % 2;
          canvas.drawText(
            offset + Offset(indicatorRect.left + x, indicatorRect.top + y),
            overflowPattern[patternIndex],
            style: overflowStyle,
          );
        }
      }

      // Draw overflow amount text in the center of the indicator
      final overflowText = '↓${_overflow.toStringAsFixed(0)}px';
      if (indicatorRect.width >= overflowText.length &&
          indicatorRect.height >= 1) {
        final textX = (indicatorRect.width - overflowText.length) / 2;
        final textY = indicatorRect.top + (indicatorRect.height / 2).floor();
        canvas.drawText(
          offset + Offset(textX, textY),
          overflowText,
          style: TextStyle(
            color: Colors.brightWhite,
            backgroundColor: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
  }
}
