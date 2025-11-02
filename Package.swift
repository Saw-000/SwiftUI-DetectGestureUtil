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
                MyModule.swiftUIDetectGestureUtil.name // "SwiftUI-DetectGestureUtil"
            ]
        ),
    ],
    targets: [
        .target(
            name: MyModule.swiftUIDetectGestureUtil.name,
            dependencies: [
                MyModule.featureDetectGesture.dependency
            ],
            path: MyModule.swiftUIDetectGestureUtil.folderPath
        ),
        .target(
            name: MyModule.featureDetectGesture.name,
            dependencies: [
                MyModule.core.dependency
            ],
            path: MyModule.featureDetectGesture.folderPath
        ),
        .target(
            name: MyModule.core.name,
            path: MyModule.core.folderPath
        )
    ]
)

// MARK: - Utility

// 自作モジュール
enum MyModule {
    case core
    case featureDetectGesture
    case swiftUIDetectGestureUtil

    var folderPath: String {
        return switch self {
        case .core:
            "Sources/Core"
        case .featureDetectGesture:
            "Sources/Feature/DetectGesture"
        case .swiftUIDetectGestureUtil:
            "Sources/SwiftUIDetectGestureUtil"
        }
    }

    var name: String {
        return switch self {
        case .swiftUIDetectGestureUtil:
            "SwiftUI-DetectGestureUtil"
        default:
            "MyModule" + folderPath
                .replacingOccurrences(of: "Sources", with: "")
                .replacingOccurrences(of: "/", with: "")
        }
    }

    var dependency: Target.Dependency {
        return .byName(name: name, condition: nil)
    }
}
