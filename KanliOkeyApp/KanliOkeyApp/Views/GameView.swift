import SwiftUI
import GameKit

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showMultiplayerOptions = false
    
    var body: some View {
        VStack {
            // Game status
            HStack {
                Text("Current Player: \(viewModel.currentPlayer.name)")
                    .font(.headline)
                
                Spacer()
                
                Text("Per: \(viewModel.per)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                if viewModel.isMultiplayer {
                    Button(action: {
                        showMultiplayerOptions = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            
            // Gösterge tile
            if let gosterge = viewModel.gostergeTile {
                VStack {
                    Text("Gösterge")
                        .font(.caption)
                    TileView(tile: gosterge, isSelected: false)
                }
                .padding()
            }
            
            // Player's rack
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.currentPlayer.rack) { tile in
                        TileView(tile: tile, isSelected: viewModel.selectedTiles.contains(tile))
                            .onTapGesture {
                                viewModel.selectTile(tile)
                            }
                    }
                }
                .padding()
            }
            .frame(height: 100)
            .background(Color.gray.opacity(0.2))
            
            // Game controls
            HStack(spacing: 20) {
                Button("Draw Tile") {
                    viewModel.drawTile()
                }
                .buttonStyle(.bordered)
                
                Button("Play Selected") {
                    viewModel.playSelectedTiles()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedTiles.isEmpty)
                
                Button("Discard Selected") {
                    if let tile = viewModel.selectedTiles.first {
                        viewModel.discardTile(tile)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedTiles.isEmpty)
            }
            .padding()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if let winner = viewModel.checkForWinner() {
                Text("Winner: \(winner.name)!")
                    .font(.title)
                    .foregroundColor(.green)
                    .padding()
            }
            
            if !viewModel.currentPlayerHasOpened {
                Text("First play must be at least 51 points")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding()
            }
        }
        .sheet(isPresented: $showMultiplayerOptions) {
            MultiplayerOptionsView(viewModel: viewModel)
        }
    }
}

struct MultiplayerOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: GameViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("Host Game") {
                        viewModel.startMultiplayerGame()
                        dismiss()
                    }
                    
                    Button("Join Game") {
                        viewModel.joinMultiplayerGame()
                        dismiss()
                    }
                }
                
                Section {
                    Button("Disconnect") {
                        viewModel.multiplayerManager.disconnect()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Multiplayer")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
}

struct TileView: View {
    let tile: Tile
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tileColor)
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            
            VStack {
                Text("\(tile.number)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                if tile.isJoker {
                    Text("Joker")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var tileColor: Color {
        switch tile.color {
        case .red:
            return .red
        case .blue:
            return .blue
        case .black:
            return .black
        case .yellow:
            return .yellow
        }
    }
}

#Preview {
    GameView()
} 