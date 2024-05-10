//
//  main.swift
//  mposplit
//
//  Created by Scott Jann on 5/9/24.
//
// https://stackoverflow.com/questions/42770462/open-mpo-file-and-extract-the-embedded-images
//

import Foundation

let header = Data([0xFF, 0xD8, 0xFF, 0xE1] as [UInt8])

for arg in CommandLine.arguments.dropFirst() {
	let url = URL(fileURLWithPath: arg)

	guard FileManager.default.fileExists(atPath: arg) else {
		print("Can't open \(arg)")
		exit(1)
	}

	guard let data = try? Data(contentsOf: url) else {
		print("Can't read from \(arg)")
		exit(1)
	}

	var markerLocations = [Int]()
	var markerOffset = data.range(of: header, options:[], in: 0..<data.count)

	while let offset = markerOffset {
		markerLocations.append(offset.lowerBound)
		markerOffset = data.range(of: header, options:[], in: offset.upperBound..<data.count)
	}

	guard markerLocations.count > 0 else {
		print("Could not find images in \(arg)")
		exit(1)
	}

	print("Found \(markerLocations.count) image\(markerLocations.count == 1 ? "" : "s") in \(arg)")

	for (index, imageOffset) in markerLocations.enumerated() {
		let output = URL(fileURLWithPath: url.deletingPathExtension().path() + "-\(index).jpg")
		let endOffset = index == markerLocations.count - 1 ? data.count : markerLocations[index + 1]
		let image = data.subdata(in: imageOffset..<endOffset)

		print("Writing image \(index) to \(output.path())")

		do {
			try image.write(to: output)
		} catch {
			print("Unable to write image file \(output.path()): \(error.localizedDescription)")
		}
	}
}
