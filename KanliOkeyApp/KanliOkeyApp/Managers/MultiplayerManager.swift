import Foundation
import GameKit
import SwiftUI

class MultiplayerManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentMatch: GKMatch?
    @Published var players: [GKPlayer] = []
    @Published var errorMessage: String?
    
    static let shared = MultiplayerManager()
    private var matchmaker: GKMatchmaker?
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Present the view controller if needed
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(viewController, animated: true)
                }
            } else if let error = error {
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            } else if GKLocalPlayer.local.isAuthenticated {
                self.isAuthenticated = true
                self.matchmaker = GKMatchmaker.shared()
            }
        }
    }
    
    func findMatch(minPlayers: Int = 2, maxPlayers: Int = 4) {
        guard isAuthenticated else {
            errorMessage = "Player not authenticated"
            return
        }
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        request.inviteMessage = "Join my Okey Plus game!"
        
        matchmaker?.findMatch(for: request) { [weak self] match, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Matchmaking failed: \(error.localizedDescription)"
                    return
                }
                
                if let match = match {
                    self?.currentMatch = match
                    match.delegate = self
                    self?.players = match.players
                }
            }
        }
    }
    
    func sendGameState(_ gameState: MultiplayerGameState) {
        guard let match = currentMatch else { return }
        
        do {
            let data = try JSONEncoder().encode(gameState)
            try match.send(data, to: match.players, dataMode: .reliable)
        } catch {
            errorMessage = "Failed to send game state: \(error.localizedDescription)"
        }
    }
    
    func disconnect() {
        currentMatch?.disconnect()
        currentMatch = nil
        players = []
    }
}

// MARK: - GKMatchDelegate
extension MultiplayerManager: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        do {
            let gameState = try JSONDecoder().decode(MultiplayerGameState.self, from: data)
            // Handle received game state
            NotificationCenter.default.post(name: .gameStateReceived, object: gameState)
        } catch {
            errorMessage = "Failed to decode game state: \(error.localizedDescription)"
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.players.contains(player) {
                    self.players.append(player)
                }
            case .disconnected:
                self.players.removeAll { $0 == player }
            default:
                break
            }
        }
    }
}

// MARK: - MultiplayerGameState
struct MultiplayerGameState: Codable {
    let currentPlayerIndex: Int
    let players: [PlayerState]
    let selectedTiles: [Tile]
    let per: Int
    let hasOpened: [Bool]
    
    struct PlayerState: Codable {
        let id: String
        let name: String
        let rack: [Tile]
        let score: Int
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let gameStateReceived = Notification.Name("gameStateReceived")
} 
