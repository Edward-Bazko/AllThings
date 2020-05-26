import UIKit

class Item {
    var description: String?
    var timestamp: Date = Date()
    
    var thumbnail: UIImage?
    var originalImage: UIImage?
    
    var loadThumbnail: () -> UIImage? = { return nil }
    var loadOriginalImage: () -> UIImage? = { return nil }
}

class ServiceContainer {
    static var shared = ServiceContainer()
    lazy var itemRepository = ItemRepository()
}

class ItemRepository {
    
    var items: [Item] = []
    
    func insert(_ item: Item) {
        items.append(item)
        items.sort { (lhs, rhs) -> Bool in
            return lhs.timestamp.timeIntervalSinceReferenceDate > rhs.timestamp.timeIntervalSinceReferenceDate
        }
    }
    
    var catalogItems: [Item] {
        return items
    }
}
