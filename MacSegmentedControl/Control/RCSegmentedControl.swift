//
//  RCSegmentedControl.swift
//  MacSegmentedControl
//
//  Created by Jeffrey Dlouhy
//

import Cocoa

private let kBackgroundCornerRadius: CGFloat = 8.91

/// An individual stack item.
struct SegmentItem {
  let text: String
}

/// A NSStackView with disabled interactions.
private class NonInteractingStackView: NSStackView {
  override func hitTest(_ point: NSPoint) -> NSView? { return nil }
}

typealias SelectedSegmentBlock = ((_ segment: SegmentItem, _ index: Int) -> Void)

// MARK: - RCSegmentedControl

class RCSegmentedControl: NSControl {
  /// The individual segments that make up the selector.
  var items: [SegmentItem] = []
  /// This block is called when the selection has changed.
  var didSelectSegment: SelectedSegmentBlock?

  private let selectionIndicator = RCSegmentedSelection()
  private let itemStackView = NSStackView()
  private let shadowStackView = NonInteractingStackView()
  private var lastHapticTap = Date()
  private var isMouseDragging: Bool = false

  private var currentSelectedIndex: Int = 0 {
    didSet {
      if let selectedSegment = selectedSegment {
        didSelectSegment?(selectedSegment, currentSelectedIndex)
      }
    }
  }

  var selectedSegment: SegmentItem? {
    guard !items.isEmpty else { return nil }
    return items[currentSelectedIndex]
  }

  // MARK: Lifecycle


  /// Initialize a segmented control with the given items and a callback for when the selection changes.
  /// - Parameters:
  ///   - items: Ordered segment items that make up the selector.
  ///   - didSelectSegment: Callback for when the selection changes, passing back a segment and it's index.
  convenience init(items: [SegmentItem], didSelectSegment: SelectedSegmentBlock? = nil) {
    self.init()
    self.items = items
    self.didSelectSegment = didSelectSegment
    setup()
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    layer = CALayer()
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = kBackgroundCornerRadius
    layer?.borderWidth = 0.5

    updateControlColors()

    itemStackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(itemStackView)

    NSLayoutConstraint.activate([
      itemStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      itemStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      itemStackView.topAnchor.constraint(equalTo: topAnchor),
      itemStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    setupStackView(itemStackView, with: items)
    setupSelectionIndicator()

      // This is stack view that mirrors the other, but just for masking purposes
    shadowStackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(shadowStackView, positioned: .above, relativeTo: selectionIndicator)

    NSLayoutConstraint.activate([
      shadowStackView.leadingAnchor.constraint(equalTo: itemStackView.leadingAnchor),
      shadowStackView.trailingAnchor.constraint(equalTo: itemStackView.trailingAnchor),
      shadowStackView.topAnchor.constraint(equalTo: itemStackView.topAnchor),
      shadowStackView.bottomAnchor.constraint(equalTo: itemStackView.bottomAnchor)
    ])

    setupStackView(shadowStackView, with: items, isMasked: true)
    shadowStackView.layer?.backgroundColor = NSColor.red.cgColor
  }

  // MARK: Internal

  override var wantsUpdateLayer: Bool { true }

  override func layout() {
    super.layout()
    updateControlColors()
    updateSelectionIndicatorFrameIfNeeded()
  }

  override func updateLayer() {
    super.updateLayer()
    updateControlColors()
  }

  override func viewDidMoveToSuperview() {
    super.viewDidMoveToSuperview()

    // Note: This is a hack because we're not getting a layout call when
    // the stack view finishes drawing on the first pass, so the frame is wrong.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.updateSelectionIndicatorFrameIfNeeded()
    }
  }

  @objc
  private func didSelectSegmentItem(sender: NSButton) {
    print("selector item: \(sender.tag) selected")
    let selectedIndex = sender.tag
    guard sender.tag < itemStackView.arrangedSubviews.count && sender.tag < items.count else { return }

    selectSegment(at: selectedIndex, with: convert(sender.frame, from: sender.superview))
  }

  private func getSegmentFrame(for segmentIndex: Int) -> NSRect? {
    guard segmentIndex < itemStackView.arrangedSubviews.count,
      let segmentButton = (itemStackView.arrangedSubviews[segmentIndex] as? RCSegment)?.itemButton else { return nil }

    return convert(segmentButton.frame, from: segmentButton.superview)
  }

  /// Select a segment at the given index.
  /// - Parameter index: The index to select, as long as it is in bounds.
  func selectSegment(at index: Int) {
    selectSegment(at: index, with: nil)
  }

  private func selectSegment(at index: Int, with frame: NSRect? = nil) {
    var selectionFrame: NSRect = frame ?? .zero
    // If the frame was nil, try and get the frame manually
    if frame == nil {
      selectionFrame = getSegmentFrame(for: index) ?? .zero
    }

    updateSeparators(with: index)
    updateSelectionIndicatorFrame(with: selectionFrame, animated: true)
    selectionIndicator.becomeFirstResponder()
    currentSelectedIndex = index
  }

  /// Used to update the indicator frame if their was a layout change
  private func updateSelectionIndicatorFrameIfNeeded() {
    if !isMouseDragging {
      updateSelectionIndicatorFrame(with: getSegmentFrame(for: currentSelectedIndex))
    }
  }

  /// Update the selection indicator frame with a reference frame of the segment to draw over.
  /// - Parameter referenceFrame: The frame of the segment to draw over, usually.
  private func updateSelectionIndicatorFrame(with referenceFrame: NSRect? = nil, animated: Bool = false) {
    var newSelectionFrame = referenceFrame ?? .zero
    newSelectionFrame.origin.y = bounds.origin.y
    newSelectionFrame.size.height = bounds.height
    newSelectionFrame = NSInsetRect(newSelectionFrame, 4, 4)

    if animated {
      selectionIndicator.animator().frame = newSelectionFrame.integral
    } else {
      selectionIndicator.frame = newSelectionFrame.integral
    }

    updateSelectionMask(with: newSelectionFrame.integral, animated: animated)
  }

  private func updateSeparators(with selectionIndex: Int?) {
    for (index, item) in itemStackView.arrangedSubviews.enumerated() {
      if let segment = item as? RCSegment {
          // Hide the separator for this segment and the next one if needed
        let shouldShow: Bool
        if let selectionIndex = selectionIndex {
          shouldShow = ((index != selectionIndex && index != selectionIndex + 1) && index > 0)
        } else {
          // If there is no selection, show all separators except the first
          shouldShow = index > 0
        }
        segment.showLeadingSeparator(shouldShow, animated: true)
      }
    }
  }

  private func setupStackView(_ stackView: NSStackView, with items: [SegmentItem], isMasked: Bool = false) {
    stackView.orientation = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0

    stackView.subviews.removeAll()

    for (index, item) in items.enumerated() {
      let itemButton = RCSegment(title: item.text,
                                 tag: index,
                                 target: isMasked ? nil : self,
                                 action: isMasked ? nil : #selector(RCSegmentedControl.didSelectSegmentItem(sender:)),
                                 isMasked: isMasked)

      let shouldShowSeparator = index > 0 && index < items.count
      itemButton.showLeadingSeparator(shouldShowSeparator, animated: false)
      stackView.addArrangedSubview(itemButton)
    }
  }

  private func setupSelectionIndicator() {
    selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
    addSubview(selectionIndicator)
  }

  // MARK: Private

  private func updateControlColors() {
    layer?.backgroundColor = NSColor(named: "selectorControlBackground")?.cgColor
    layer?.borderColor = NSColor.controlColor.withAlphaComponent(0.2).cgColor
    layer?.masksToBounds = false
    layer?.shadowRadius = 6
    layer?.shadowOffset = .init(width: 0, height: -3)
    layer?.shadowOpacity = 0.04
    layer?.shadowPath = .init(rect: bounds, transform: nil)
  }

  override func keyDown(with event: NSEvent) {
    if event.modifierFlags.contains(.numericPad) {
      interpretKeyEvents([event])
    }
  }

  override func moveLeft(_ sender: Any?) {
    guard currentSelectedIndex > 0, !items.isEmpty else { return }
    selectSegment(at: currentSelectedIndex - 1)
  }

  override func moveRight(_ sender: Any?) {
    guard currentSelectedIndex + 1 < items.count, !items.isEmpty else { return }
    selectSegment(at: currentSelectedIndex + 1)
  }

  override func mouseDown(with event: NSEvent) {
    guard isEnabled || (window?.makeFirstResponder(self))! else { return }
    let location = convert(event.locationInWindow, from: nil)

    // Start dragging if the mouse is in the selection indicator
    if selectionIndicator.frame.contains(location) {
      startMouseDragging(with: event)
    }
  }

  private func startMouseDragging(with event: NSEvent) {
    var shouldLoop = true
    var latestEvent = event
    // Set this so we can disable some custom drawing if needed while dragging.
    isMouseDragging = true
    // Take control of the cursor
    window?.disableCursorRects()
    // Use the Micky Mouse hand
    NSCursor.closedHand.push()
    // Hide the separators
    updateSeparators(with: nil)
    // Reset the cursor and other state when we return
    defer {
      NSCursor.closedHand.pop()
      window?.enableCursorRects()
      snapSelectionIndicatorToClosestSegment()
      isMouseDragging = false
    }

    // Center the indicator under the view
    moveIndicator(to: convert(latestEvent.locationInWindow, from: nil))

    let eventMask: NSEvent.EventTypeMask = [.leftMouseUp, .leftMouseDragged]
    let untilDate: Date = .distantFuture

    repeat {
      let mousePoint = convert(latestEvent.locationInWindow, from: nil)

      switch latestEvent.type {
        case .leftMouseDown, .leftMouseDragged:
          guard let latestEventInWindow = window?.nextEvent(matching: eventMask, until: untilDate, inMode: .eventTracking, dequeue: true) else {
            // If we can't get the event, bail
            shouldLoop = false
            continue
          }
          // Set the latest event
          latestEvent = latestEventInWindow
          moveIndicator(to: mousePoint)
          needsLayout = true
        default:
          shouldLoop = false
      }
    } while shouldLoop
  }

  private func moveIndicator(to point: NSPoint) {
    let convertedPoint = convert(point, to: itemStackView)

    var nextFrame = selectionIndicator.frame

    // Don't allow the X position to go past a value that would draw past the bounds
    let minimumAllowedX = max(0, convertedPoint.x - (nextFrame.width / 2))
    let maximumAllowedX = min(minimumAllowedX, (itemStackView.bounds.maxX - selectionIndicator.bounds.width))

    let nextX = min(minimumAllowedX, maximumAllowedX)
    nextFrame.origin.x = nextX

    selectionIndicator.frame = nextFrame
    updateSelectionMask(with: nextFrame)

    maybePerformHapticFeedbackForDragOverlap()
  }

  private func updateSelectionMask(with selectionFrame: NSRect, animated: Bool = false) {
    let maskLayer = CAShapeLayer()
    let path = CGPath(rect: selectionFrame, transform: nil)
    maskLayer.path = path
    maskLayer.fillRule = .nonZero

    if animated {
      shadowStackView.animator().layer?.mask = maskLayer
    } else {
      shadowStackView.layer?.mask = maskLayer
    }
  }

  typealias SegmentIntersectionTuple = (segment: RCSegment, intersection: NSRect)

  private func segmentIntersections(with referenceFrame: NSRect) -> [SegmentIntersectionTuple] {
    // Get all the frames of the segments
    itemStackView.arrangedSubviews.compactMap { subview in
      guard let arrangedSegment = subview as? RCSegment else { return nil }
      // Calculate the intersection amount.
      let frameIntersection = NSIntersectionRect(arrangedSegment.frame, referenceFrame)
      // Return a tuple of the segment and the overlap.
      return (arrangedSegment, frameIntersection)
    }
  }

  /// When the overlap of the selector and a segment are equal widths perform an alignment haptic feedback.
  private func maybePerformHapticFeedbackForDragOverlap() {
    // Don't tap again too soon if hovering over a space.
    guard abs(lastHapticTap.timeIntervalSince(Date())) > 0.5 else { return }

    let currentSelectionFrameInStackView = convert(selectionIndicator.frame, to: itemStackView).integral
    let segmentFrameIntersections = segmentIntersections(with: currentSelectionFrameInStackView)

    // Check if we're fully overlapped with a whole segment.
    guard segmentFrameIntersections.contains(where: { NSWidth($0.intersection.integral) == currentSelectionFrameInStackView.width}) else { return }
    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    lastHapticTap = Date()
  }

  /// Select the segment that has the most overlap with the selector.
  private func snapSelectionIndicatorToClosestSegment() {
    let currentSelectionFrameInStackView = convert(selectionIndicator.frame, to: itemStackView)
    let segmentFrameIntersections = segmentIntersections(with: currentSelectionFrameInStackView)

    let greatestOverlappingSegment = segmentFrameIntersections
      .sorted(by: { NSWidth($0.intersection) > NSWidth($1.intersection) })
      .first

    if let segmentButton = greatestOverlappingSegment?.segment.itemButton {
      didSelectSegmentItem(sender: segmentButton)
    }
  }
}
