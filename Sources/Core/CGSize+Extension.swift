import Foundation

public extension CGSize {
    var distance: CGFloat {
        return sqrt(width * width + height * height)
    }
}
