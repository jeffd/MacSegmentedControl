//
//  RCSegmentedSelection.swift
//  MacSegmentedControl
//
//  Created by Jeffrey Dlouhy
//

import Cocoa

class RCSegmentedSelection: NSView {
  // MARK: Lifecycle

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  // MARK: Internal

  override var wantsUpdateLayer: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  private var trackingArea: NSTrackingArea?

  override func layout() {
    super.layout()
    updateControlColors()
  }

  override func updateLayer() {
    super.updateLayer()
    updateControlColors()
  }

  // MARK: Private

  private func setup() {
    layer = CALayer()
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = 6.93
    layer?.borderWidth = 0.5

    layer?.masksToBounds = false
    layer?.shadowRadius = 8
    layer?.shadowOffset = .init(width: 0, height: -3)
    layer?.shadowOpacity = 1

    updateControlColors()
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

      // Remove our old tracking area
    if let oldTrackingArea = trackingArea {
      removeTrackingArea(oldTrackingArea)
    }

    let newTrackingArea = NSTrackingArea(rect: bounds,
                                         options: [.mouseEnteredAndExited, .inVisibleRect, .activeInActiveApp, .mouseMoved],
                                         owner: self,
                                         userInfo: nil)
    addTrackingArea(newTrackingArea)
    trackingArea = newTrackingArea
  }

  override func mouseDown(with event: NSEvent) {
    handleMouseEvent(event)
    nextResponder?.mouseDown(with: event)
  }

  override func mouseEntered(with event: NSEvent) {
    handleMouseEvent(event)
  }

  override func mouseExited(with event: NSEvent) {
    handleMouseEvent(event)
  }

  override func mouseUp(with event: NSEvent) {
    handleMouseEvent(event)
  }

  func handleMouseEvent(_ event: NSEvent) {
    var nextControlColor: NSColor?

    switch event.type {
      case .mouseEntered:
        nextControlColor = NSColor.controlColor.withSystemEffect(.rollover)
      case .leftMouseDown:
        nextControlColor = NSColor.controlColor.withSystemEffect(.pressed)
      default:
        nextControlColor = NSColor.controlColor
    }

    layer?.backgroundColor = nextControlColor?.cgColor
  }

  private func updateControlColors() {
    layer?.backgroundColor = NSColor.controlColor.cgColor
    layer?.borderColor = NSColor.controlColor.withAlphaComponent(0.2).cgColor
    layer?.shadowColor = NSColor.shadowColor.cgColor

    layer?.masksToBounds = false
    layer?.shadowRadius = 8
    layer?.shadowOffset = .init(width: 0, height: -3)
    layer?.shadowOpacity = 0.12
    layer?.shadowPath = .init(rect: bounds, transform: nil)
  }
}
