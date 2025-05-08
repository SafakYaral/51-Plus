import Foundation

class GameBoard {
    private(set) var tiles: [Tile]
    private(set) var players: [Player]
    private(set) var currentPlayerIndex: Int
    private(set) var okeyTile: Tile?
    private(set) var gostergeTile: Tile?
    private(set) var hasOpened: [Bool]
    private(set) var per: Int
    
    init(numberOfPlayers: Int) {
        self.tiles = []
        self.players = []
        self.currentPlayerIndex = 0
        self.hasOpened = Array(repeating: false, count: numberOfPlayers)
        self.per = 0
        
        // Initialize tiles
        for color in TileColor.allCases {
            for number in 1...13 {
                // Add two tiles of each number and color
                tiles.append(Tile(number: number, color: color))
                tiles.append(Tile(number: number, color: color))
            }
        }
        
        // Add jokers
        tiles.append(Tile(number: 0, color: .red, isJoker: true))
        tiles.append(Tile(number: 0, color: .red, isJoker: true))
        
        // Initialize players
        for i in 0..<numberOfPlayers {
            players.append(Player(name: "Player \(i + 1)"))
        }
        
        shuffleTiles()
        dealInitialTiles()
    }
    
    private func shuffleTiles() {
        tiles.shuffle()
    }
    
    private func dealInitialTiles() {
        // Deal 14 tiles to each player
        for _ in 0..<14 {
            for i in 0..<players.count {
                if let tile = tiles.popLast() {
                    players[i].addTile(tile)
                }
            }
        }
        
        // Set gösterge tile and determine okey tile
        if let gosterge = tiles.popLast() {
            gostergeTile = gosterge
            // Okey tile is the next number after gösterge
            let okeyNumber = gosterge.number == 13 ? 1 : gosterge.number + 1
            okeyTile = Tile(number: okeyNumber, color: gosterge.color)
            
            // Add the okey tile to the remaining tiles instead of keeping it on the desk
            tiles.append(okeyTile!)
        }
    }
    
    func drawTile() -> Tile? {
        guard !tiles.isEmpty else { return nil }
        return tiles.popLast()
    }
    
    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    func calculatePoints(_ tiles: [Tile]) -> Int {
        var points = 0
        for tile in tiles {
            if tile.isJoker {
                points += 30
            } else if tile == okeyTile {
                points += 20
            } else {
                points += tile.number
            }
        }
        return points
    }
    
    func isValidCombination(_ tiles: [Tile]) -> Bool {
        // Check for sets (same number, different colors)
        if isSet(tiles) { return true }
        
        // Check for runs (same color, consecutive numbers)
        if isRun(tiles) { return true }
        
        return false
    }
    
    private func isSet(_ tiles: [Tile]) -> Bool {
        guard tiles.count >= 3 else { return false }
        
        // Count regular tiles and okey tiles
        let regularTiles = tiles.filter { !$0.isJoker && $0 != okeyTile }
        let okeyCount = tiles.filter { $0.isJoker || $0 == okeyTile }.count
        
        // All regular tiles must have the same number
        let numbers = regularTiles.map { $0.number }
        guard numbers.allSatisfy({ $0 == numbers[0] }) else { return false }
        
        // Colors must be unique
        let colors = Set(regularTiles.map { $0.color })
        
        // Check if we have enough unique colors with okey tiles
        return colors.count + okeyCount >= 3
    }
    
    private func isRun(_ tiles: [Tile]) -> Bool {
        guard tiles.count >= 3 else { return false }
        
        // Count regular tiles and okey tiles
        let regularTiles = tiles.filter { !$0.isJoker && $0 != okeyTile }
        let okeyCount = tiles.filter { $0.isJoker || $0 == okeyTile }.count
        
        // All regular tiles must have the same color
        let colors = Set(regularTiles.map { $0.color })
        guard colors.count == 1 else { return false }
        
        // Sort regular tiles by number
        let sortedTiles = regularTiles.sorted { $0.number < $1.number }
        
        // Check for gaps that can be filled with okey tiles
        var remainingOkeys = okeyCount
        for i in 1..<sortedTiles.count {
            let gap = sortedTiles[i].number - sortedTiles[i-1].number - 1
            if gap > 0 {
                if gap > remainingOkeys {
                    return false
                }
                remainingOkeys -= gap
            }
        }
        
        return true
    }
    
    func canOpen(_ tiles: [Tile]) -> Bool {
        return calculatePoints(tiles) >= 51
    }
    
    func markAsOpened(playerIndex: Int) {
        hasOpened[playerIndex] = true
    }
    
    func updatePer(_ points: Int) {
        per += points
    }
    
    // Methods to update player state
    func addTileToPlayer(_ tile: Tile, playerIndex: Int) {
        players[playerIndex].addTile(tile)
    }
    
    func removeTilesFromPlayer(_ tiles: [Tile], playerIndex: Int) {
        for tile in tiles {
            players[playerIndex].removeTile(tile)
        }
    }
    
    func addPointsToPlayer(_ points: Int, playerIndex: Int) {
        players[playerIndex].updateScore(points)
    }
    
    // Methods for multiplayer state updates
    func updatePlayerRack(_ rack: [Tile], playerIndex: Int) {
        guard playerIndex < players.count else { return }
        players[playerIndex].rack = rack
    }
    
    func setPlayerScore(_ score: Int, playerIndex: Int) {
        guard playerIndex < players.count else { return }
        players[playerIndex].score = score
    }
    
    func updateOpenedStatus(_ status: [Bool]) {
        guard status.count == hasOpened.count else { return }
        hasOpened = status
    }
    
    func setCurrentPlayerIndex(_ index: Int) {
        guard index < players.count else { return }
        currentPlayerIndex = index
    }
} 