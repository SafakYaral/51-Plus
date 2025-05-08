import Foundation

struct Player: Identifiable, Codable {
    let id: UUID
    let name: String
    var rack: [Tile]
    var score: Int
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.rack = []
        self.score = 0
    }
    
    mutating func addTile(_ tile: Tile) {
        rack.append(tile)
    }
    
    mutating func removeTile(_ tile: Tile) {
        if let index = rack.firstIndex(of: tile) {
            rack.remove(at: index)
        }
    }
    
    mutating func updateScore(_ points: Int) {
        score += points
    }
} 
