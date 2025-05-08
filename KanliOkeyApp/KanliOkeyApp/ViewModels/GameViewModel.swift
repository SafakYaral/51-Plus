import Foundation
import SwiftUI
import GameKit

class GameViewModel: ObservableObject {
    @Published private(set) var gameBoard: GameBoard
    @Published private(set) var selectedTiles: [Tile] = []
    @Published private(set) var gameState: GameState = .playing
    @Published private(set) var errorMessage: String?
    @Published private(set) var showGosterge: Bool = false
    @Published private(set) var isMultiplayer: Bool = false
    @Published private(set) var isHost: Bool = false
    
    let multiplayerManager = MultiplayerManager.shared
    
    enum GameState {
        case playing
        case gameOver
    }
    
    init(numberOfPlayers: Int = 4, isMultiplayer: Bool = false) {
        self.gameBoard = GameBoard(numberOfPlayers: numberOfPlayers)
        self.isMultiplayer = isMultiplayer
        
        if isMultiplayer {
            setupMultiplayer()
        }
    }
    
    private func setupMultiplayer() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameStateReceived),
            name: .gameStateReceived,
            object: nil
        )
    }
    
    @objc private func handleGameStateReceived(_ notification: Notification) {
        guard let gameState = notification.object as? MultiplayerGameState else { return }
        
        DispatchQueue.main.async {
            // Update game state with received data
            self.updateGameState(gameState)
        }
    }
    
    private func updateGameState(_ gameState: MultiplayerGameState) {
        // Update players
        for (index, playerState) in gameState.players.enumerated() {
            if index < self.gameBoard.players.count {
                // Update existing player
                self.gameBoard.updatePlayerRack(playerState.rack, playerIndex: index)
                self.gameBoard.setPlayerScore(playerState.score, playerIndex: index)
            }
        }
        
        // Update other game state
        self.selectedTiles = gameState.selectedTiles
        self.gameBoard.updatePer(gameState.per)
        self.gameBoard.updateOpenedStatus(gameState.hasOpened)
        self.gameBoard.setCurrentPlayerIndex(gameState.currentPlayerIndex)
    }
    
    func startMultiplayerGame() {
        isMultiplayer = true
        isHost = true
        multiplayerManager.findMatch(minPlayers: 2, maxPlayers: 4)
    }
    
    func joinMultiplayerGame() {
        isMultiplayer = true
        isHost = false
        multiplayerManager.findMatch(minPlayers: 2, maxPlayers: 4)
    }
    
    private func syncGameState() {
        guard isMultiplayer else { return }
        
        let gameState = MultiplayerGameState(
            currentPlayerIndex: gameBoard.currentPlayerIndex,
            players: gameBoard.players.map { player in
                MultiplayerGameState.PlayerState(
                    id: player.id.uuidString,
                    name: player.name,
                    rack: player.rack,
                    score: player.score
                )
            },
            selectedTiles: selectedTiles,
            per: gameBoard.per,
            hasOpened: gameBoard.hasOpened
        )
        
        multiplayerManager.sendGameState(gameState)
    }
    
    var currentPlayer: Player {
        gameBoard.players[gameBoard.currentPlayerIndex]
    }
    
    var currentPlayerHasOpened: Bool {
        gameBoard.hasOpened[gameBoard.currentPlayerIndex]
    }
    
    var gostergeTile: Tile? {
        gameBoard.gostergeTile
    }
    
    var okeyTile: Tile? {
        gameBoard.okeyTile
    }
    
    var per: Int {
        gameBoard.per
    }
    
    func selectTile(_ tile: Tile) {
        if let index = selectedTiles.firstIndex(of: tile) {
            selectedTiles.remove(at: index)
        } else {
            selectedTiles.append(tile)
        }
        
        if isMultiplayer {
            syncGameState()
        }
    }
    
    func drawTile() {
        guard let tile = gameBoard.drawTile() else {
            gameState = .gameOver
            return
        }
        
        gameBoard.addTileToPlayer(tile, playerIndex: gameBoard.currentPlayerIndex)
        
        if isMultiplayer {
            syncGameState()
        }
    }
    
    func playSelectedTiles() {
        // Check if player has opened
        if !currentPlayerHasOpened {
            guard gameBoard.canOpen(selectedTiles) else {
                errorMessage = "First play must be at least 51 points"
                return
            }
            gameBoard.markAsOpened(playerIndex: gameBoard.currentPlayerIndex)
        }
        
        guard gameBoard.isValidCombination(selectedTiles) else {
            errorMessage = "Invalid combination"
            return
        }
        
        // Calculate points for the play
        let points = gameBoard.calculatePoints(selectedTiles)
        gameBoard.updatePer(points)
        
        // Remove played tiles from player's rack
        gameBoard.removeTilesFromPlayer(selectedTiles, playerIndex: gameBoard.currentPlayerIndex)
        
        selectedTiles.removeAll()
        gameBoard.nextTurn()
        
        if isMultiplayer {
            syncGameState()
        }
    }
    
    func discardTile(_ tile: Tile) {
        gameBoard.removeTilesFromPlayer([tile], playerIndex: gameBoard.currentPlayerIndex)
        gameBoard.nextTurn()
        
        if isMultiplayer {
            syncGameState()
        }
    }
    
    func checkForWinner() -> Player? {
        return gameBoard.players.first { $0.rack.isEmpty }
    }
    
    func toggleGosterge() {
        showGosterge.toggle()
    }
    
    deinit {
        if isMultiplayer {
            NotificationCenter.default.removeObserver(self)
            multiplayerManager.disconnect()
        }
    }
} 