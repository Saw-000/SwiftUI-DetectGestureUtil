import Foundation

public extension Sequence {
    func distinctBy<T: Hashable>(by key: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(key($0)).inserted }
    }
}

extension Sequence where Element: Equatable {
    func distinct() -> [Element] {
        var result: [Element] = []
        for e in self where !result.contains(e) {
            result.append(e)
        }
        return result
    }
}
