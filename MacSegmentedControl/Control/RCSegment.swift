//
//  RCSegment.swift
//  MacSegmentedControl
//
//  Created by Jeffrey Dlouhy
//

import Cocoa

class RCSegment: NSView {
  private let leadingSeparator = NSView()
  var itemButton: NSButton?

  convenience init(title: String, tag: Int, target: Any?, action: Selector?, isMasked: Bool = false) {
    self.init(frame: .zero)
    itemButton = NSButton(title: title, target: target, action: action)
    itemButton?.tag = tag
    itemButton?.isBordered = false

    // If this is a segment used for a mask, then make the font heavier and hide the separator.
    if isMasked {
      if let currentFont = itemButton?.font {
        itemButton?.font = NSFontManager.shared.convertWeight(true, of: currentFont)
        itemButton?.contentTintColor = .selectedControlTextColor
      }
      leadingSeparator.isHidden = true
    }

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

  override var acceptsFirstResponder: Bool { false }

  private func setup() {
    guard let itemButton = itemButton else { return }
    leadingSeparator.layer = CALayer()
    leadingSeparator.layer?.cornerCurve = .circular
    leadingSeparator.layer?.cornerRadius = 1
    leadingSeparator.layer?.backgroundColor = NSColor.separatorColor.cgColor
    leadingSeparator.translatesAutoresizingMaskIntoConstraints = false
    addSubview(leadingSeparator)

    itemButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(itemButton)

    NSLayoutConstraint.activate([
      leadingSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
      leadingSeparator.trailingAnchor.constraint(greaterThanOrEqualTo: itemButton.leadingAnchor),
      leadingSeparator.widthAnchor.constraint(equalToConstant: 1),
      leadingSeparator.topAnchor.constraint(equalTo: topAnchor),
      leadingSeparator.bottomAnchor.constraint(equalTo: bottomAnchor),

      itemButton.topAnchor.constraint(equalTo: topAnchor),
      itemButton.bottomAnchor.constraint(equalTo: bottomAnchor),
      itemButton.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }


    /// Show or hide the leading separator with or without animation
    /// - Parameters:
    ///   - shouldShow: if it should be shown.
    ///   - animated: If it should be animated in or out
  func showLeadingSeparator(_ shouldShow: Bool, animated: Bool = true) {
    let newOpacity: Float = shouldShow ? 1 : 0
    if animated {
      leadingSeparator.animator().layer?.opacity = newOpacity
    } else {
      leadingSeparator.layer?.opacity = newOpacity
    }
  }
}
