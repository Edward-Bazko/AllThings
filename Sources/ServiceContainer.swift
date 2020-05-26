import Foundation

class ServiceContainer {
    static var shared = ServiceContainer()
    
    lazy var itemRepository = ItemRepository()
}
