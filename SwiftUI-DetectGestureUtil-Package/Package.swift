// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-DetectGestureUtil",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftUI-DetectGestureUtil",
            targets: [
                MyModule.featureDetectGesture.name
            ]
        ),
    ],
    targets: [
        .target(
            name: MyModule.featureDetectGesture.name,
            path: MyModule.featureDetectGesture.folderPath
        )
    ]
)

// MARK: - Utility

// 自作モジュール
enum MyModule {
    case featureDetectGesture

    var folderPath: String {
        return switch self {
        case .featureDetectGesture:
            "Sources/Feature/DetectGesture"
        }
    }

    var name: String {
        return "MyModule" + folderPath
            .replacingOccurrences(of: "Sources", with: "")
            .replacingOccurrences(of: "/", with: "")
    }

    var dependency: Target.Dependency {
        return .byName(name: name, condition: nil)
    }
}

/** 外部ライブラリ */
struct ThirdParty {
    /** 外部ライブラリパッケージ */
    enum Package {
        case swiftComposableArchitecture
        case swiftAlgorithms

        var dependency: PackageDescription.Package.Dependency {
            return switch self {
            case .swiftComposableArchitecture:
                .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1")
            case .swiftAlgorithms:
                .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0")
            }
        }
    }

    /** 外部ライブラリプロダクト */
    enum Product {
        case swiftComposableArchitecture
        case swiftAlgorithms

        var targetDependency: Target.Dependency {
            return switch self {
            case .swiftComposableArchitecture:
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            case .swiftAlgorithms:
                .product(name: "Algorithms", package: "swift-algorithms")
            }
        }
    }
}
