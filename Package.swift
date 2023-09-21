// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Superagent",
	platforms: [
		.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "Superagent",
			targets: ["Superagent"]),
	],
	targets: [
			.target(
				name: "Superagent"),
			//.testTarget(
			//	name: "SuperagentTests",
			//	dependencies: ["Superagent"]),
		]
)
