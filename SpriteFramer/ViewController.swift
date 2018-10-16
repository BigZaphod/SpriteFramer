//
//  ViewController.swift
//  SpriteFramer
//
//  Created by Sean on 10/15/18.
//  Copyright © 2018 Sean. All rights reserved.
//

import Cocoa

struct Slices {
	var width: Int
	var height: Int
	var frameWidth: Int
	var frameHeight: Int
	var frames: [NSRect]
}

class ViewController: NSViewController {

	@IBOutlet var imageView: NSImageView!
	
	@IBOutlet var widthField: NSTextField!
	@IBOutlet var heightField: NSTextField!

	@IBOutlet var showGridButton: NSButton!

	@IBAction func generate(_ sender: Any) {
		guard let tiff = currentImage?.tiffRepresentation, let slices = currentSlices else {
			return
		}

		let panel = NSSavePanel()
		panel.allowedFileTypes = ["atlas"]
		panel.allowsOtherFileTypes = false
		panel.treatsFilePackagesAsDirectories = false
		
		let imageRep = NSBitmapImageRep(data: tiff)

		panel.begin { (response) in
			guard
				response == .OK,
				let packageURL = panel.url,
				let pngData = imageRep?.representation(using: .png, properties: [:])
				else {
					return
			}
			
			let name = packageURL.deletingPathExtension().lastPathComponent
			let textureURL = packageURL.appendingPathComponent(name).appendingPathExtension("png")
			let plistURL = packageURL.appendingPathComponent(name).appendingPathExtension("plist")

			var frames: [String : Any] = [:]
			
			for (index, frame) in slices.frames.enumerated() {
				let frameName = String(format: "%03d", index)
				
				frames[frameName] = [
					"spriteOffset" : "{0,0}",
					"spriteSize" : "{\(slices.frameWidth),\(slices.frameHeight)}",
					"spriteSourceSize" : "{\(slices.frameWidth),\(slices.frameHeight)}",
					"textureRect" : "{{\(frame.minX),\(frame.minY)},{\(frame.width),\(frame.height)}}",
				]
			}
			
			let plist: [String : Any] = [
				"frames" : frames,
				"metadata" : [
					"format" : 3,
					"size" : "{\(slices.width),\(slices.height)}",
					"realTextureFileName" : textureURL.lastPathComponent,
				]
			]

			do {
				try? FileManager.default.removeItem(at: packageURL)
				try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: false, attributes: nil)
				let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
				try pngData.write(to: textureURL)
				try plistData.write(to: plistURL)
			} catch {
				return
			}
		}
	}
	
	@IBAction func imageChanged(_ sender: Any) {
		currentImage = imageView.image?.copy() as? NSImage
		updateSlices()
	}

	@IBAction func clickedShowButton(_ sender: Any) {
		updateSlices()
	}

	var currentImage: NSImage?

	var currentSlices: Slices? {
		guard let image = currentImage else { return nil }

		var slices = Slices(
			width: Int(image.size.width),
			height: Int(image.size.height),
			frameWidth: widthField.integerValue,
			frameHeight: heightField.integerValue,
			frames: []
		)
		
		guard slices.frameWidth > 0 && slices.frameHeight > 0 else { return nil }
		
		for y in stride(from: 0, to: slices.height, by: slices.frameHeight) {
			for x in stride(from: 0, to: slices.width, by: slices.frameWidth) {
				slices.frames.append(.init(x: x, y: y, width: slices.frameWidth, height: slices.frameHeight))
			}
		}

		return slices
	}

	func updateSlices() {
		guard let slices = currentSlices, let slicedImage = currentImage?.copy() as? NSImage else {
			return
		}
		
		let grid = NSBezierPath()

		for x in stride(from: slices.frameWidth, to: slices.width, by: slices.frameWidth) {
			grid.move(to: NSPoint(x: x, y: 0))
			grid.line(to: NSPoint(x: x, y: slices.height))
		}

		for y in stride(from: slices.frameHeight, to: slices.height, by: slices.frameHeight) {
			grid.move(to: NSPoint(x: 0, y: y))
			grid.line(to: NSPoint(x: slices.width, y: y))
		}
		
		slicedImage.lockFocus()
		
		if showGridButton.state == .on {
			NSColor.gridColor.setStroke()
			grid.stroke()
		}
		
		slicedImage.unlockFocus()
		
		imageView.image = slicedImage
	}
}

extension ViewController: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		updateSlices()
	}
}

