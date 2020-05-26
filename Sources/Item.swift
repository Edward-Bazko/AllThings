import UIKit

class Item {
    var description: String?
    var timestamp: Date = Date()
    var thumbnail: UIImage?
    var originalImage: UIImage?
    
    private var identifier: UUID = UUID()
    
    enum CodingKeys: String, CodingKey {
        case description, timestamp
        case originalImagePath, thumbnailPath
    }
    
    init() { }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try values.decode(String.self, forKey: .description)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        try loadOriginalImage(values)
        try loadThumbnail(values)
    }
    
    private func loadOriginalImage(_ values: KeyedDecodingContainer<CodingKeys>) throws {
        let filename = try values.decode(String.self, forKey: .originalImagePath)
        let originalPath = itemsDirectory.appendingPathComponent(filename)
        let originalData = try Data(contentsOf: originalPath)
        originalImage = UIImage(data: originalData)
    }
    
    private func loadThumbnail(_ values: KeyedDecodingContainer<CodingKeys>) throws {
        let filename = try values.decode(String.self, forKey: .thumbnailPath)
        let originalPath = itemsDirectory.appendingPathComponent(filename)
        let originalData = try Data(contentsOf: originalPath)
        thumbnail = UIImage(data: originalData)
    }
}


extension Item: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(timestamp, forKey: .timestamp)
        try saveOriginalImage(&container)
        try saveThumbnail(&container)
    }
    
    private func saveOriginalImage(_ container: inout KeyedEncodingContainer<CodingKeys>) throws {
        let path = itemsDirectory.appendingPathComponent(identifier.uuidString).appendingPathExtension("png")
        try originalImage?.pngData()?.write(to: path, options: .atomic)
        try container.encode(path.lastPathComponent, forKey: .originalImagePath)
    }
    
    private func saveThumbnail(_ container: inout KeyedEncodingContainer<CodingKeys>) throws {
        let path = itemsDirectory.appendingPathComponent("\(identifier.uuidString)_thumb").appendingPathExtension("png")
        try thumbnail?.pngData()?.write(to: path, options: .atomic)
        try container.encode(path.lastPathComponent, forKey: .thumbnailPath)
    }
}


class ItemRepository {
    
    private var items: [Item] = []
    
    init() {
        do { try load() }
        catch { debugPrint("Failed to load items: \(error)")}
    }
    
    func insert(_ item: Item) {
        items.append(item)
        items.sort { (lhs, rhs) -> Bool in
            return lhs.timestamp.timeIntervalSinceReferenceDate > rhs.timestamp.timeIntervalSinceReferenceDate
        }
        do { try save() }
        catch { debugPrint("Failed to save items: \(error)") }
    }
    
    var catalogItems: [Item] {
        return items
    }
    
    private func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: itemJsonPath)
        debugPrint("Items saved to: \(itemJsonPath)")
    }
    
    private func load() throws {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: itemJsonPath)
        items = try decoder.decode([Item].self, from: data)
    }
}

var documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

private var itemsDirectory: URL = {
    let dir = documentsDirectory.appendingPathComponent("Items")
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}()

private var itemJsonPath = itemsDirectory.appendingPathComponent("items.json")
