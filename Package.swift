import PackageDescription

let package = Package(
  name: "Parsec",
  targets: [
    Target(name: "Parsec"),
    Target(name: "example-csv-simple", dependencies: [.Target(name: "Parsec")]),
    Target(name: "example-csv-advanced", dependencies: [.Target(name: "Parsec")]),
    Target(name: "example-json", dependencies: [.Target(name: "Parsec")]),
    Target(name: "sample", dependencies: [.Target(name: "Parsec")]),
  ]
)
