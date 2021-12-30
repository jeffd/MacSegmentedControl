//
//  ViewController.swift
//  MacSegmentedControl
//
//  Created by Jeffrey Dlouhy
//

import Cocoa

class ViewController: NSViewController {
  private static let testItems: [SegmentItem] = [
    SegmentItem(text: "One"),
    SegmentItem(text: "Two"),
    SegmentItem(text: "Three"),
    SegmentItem(text: "Four")
  ]

  lazy var segmentedControl = RCSegmentedControl(items: ViewController.testItems) { selectedSegment, _ in
    self.currentSelection.stringValue = selectedSegment.text
  }

  private let currentSelection = NSTextField(labelWithString: "")

  override func viewDidLoad() {
    super.viewDidLoad()

    view.layerContentsRedrawPolicy = .onSetNeedsDisplay

    segmentedControl.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(segmentedControl)

    currentSelection.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(currentSelection)

    NSLayoutConstraint.activate([
      segmentedControl.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
      segmentedControl.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      segmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
      segmentedControl.heightAnchor.constraint(equalToConstant: 32),

      segmentedControl.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 2),
      segmentedControl.trailingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.trailingAnchor, multiplier: -2),

      currentSelection.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
      currentSelection.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      currentSelection.bottomAnchor.constraint(equalTo: segmentedControl.topAnchor, constant: -48)
    ])
  }
}
