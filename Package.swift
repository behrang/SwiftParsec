import PackageDescription

let package = Package(
  targets: [
    Target(name: "example-csv-simple", dependencies: [.Target(name: "SwiftParsec")]),
    Target(name: "example-csv-advanced", dependencies: [.Target(name: "SwiftParsec")]),
    Target(name: "example-json-simple", dependencies: [.Target(name: "SwiftParsec")]),
    Target(name: "example-json-advanced", dependencies: [.Target(name: "SwiftParsec")]),
  ]
)
