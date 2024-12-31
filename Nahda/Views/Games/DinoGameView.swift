//
//  DinoGameView.swift
//  Nahda
//
//  Created by mofo on 31.12.2024.
//
import SwiftUI

struct DinoGameView: View {
    @StateObject private var gameState = DinoGameState()

    var body: some View {
        ZStack {
            // 1) Background
            Color.white
                .ignoresSafeArea()
            
            // 2) Ground line
            Rectangle()
                .fill(Color.gray)
                .frame(height: 2)
                .position(x: UIScreen.main.bounds.midX,
                          y: UIScreen.main.bounds.height * 0.8)
            
            // 3) The Dino
            DinoView(yPosition: gameState.dinoY)
                .position(x: UIScreen.main.bounds.width * 0.2,
                          y: UIScreen.main.bounds.height * 0.8 - gameState.dinoY)
            
            // 4) Obstacles
            ForEach(gameState.obstacles) { obstacle in
                ObstacleView(xPosition: obstacle.xPosition,
                             size: obstacle.size)
                .position(x: obstacle.xPosition,
                          y: UIScreen.main.bounds.height * 0.8 - obstacle.size/2)
            }
            
            // 5) Game Over text
            if gameState.isGameOver {
                VStack {
                    Text("Game Over")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Tap to retry!")
                        .foregroundColor(.gray)
                }
            }
        }
        // 6) Tap to jump or restart
        .onTapGesture {
            if gameState.isGameOver {
                gameState.startGame()
            } else {
                gameState.jump()
            }
        }
        // 7) Update game each frame
        .onReceive(gameState.timer) { _ in
            gameState.updateGame()
        }
    }
}

struct DinoGameView_Previews: PreviewProvider {
    static var previews: some View {
        DinoGameView()
    }
}

