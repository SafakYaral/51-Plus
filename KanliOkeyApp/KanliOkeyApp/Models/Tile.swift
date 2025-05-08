import Foundation

enum TileColor: String, CaseIterable, Codable {
    case red
    case blue
    case black
    case yellow
}

struct Tile: Identifiable, Equatable, Codable {
    let id: UUID
    let number: Int
    let color: TileColor
    var isJoker: Bool
    
    init(number: Int, color: TileColor, isJoker: Bool = false) {
        self.id = UUID()
        self.number = number
        self.color = color
        self.isJoker = isJoker
    }
    
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return lhs.number == rhs.number && lhs.color == rhs.color && lhs.isJoker == rhs.isJoker
    }
} 