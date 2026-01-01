import Foundation

public extension CGSize {
    /// Calculate the Euclidean distance (magnitude) of the size vector
    var distance: CGFloat {
        return sqrt(width * width + height * height)
    }
}
