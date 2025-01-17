////
////  DinoGameState.swift
////  Nahda
////
////  Created by mofo on 31.12.2024.
////
//import SwiftUI
//import Combine
//
//class DinoGameState: ObservableObject {
//    // MARK: - Published Properties
//    @Published var isGameOver = false
//    @Published var dinoY: CGFloat = 0
//    @Published var obstacles: [Obstacle] = []
//    
//    // MARK: - Game Constants
//    private let gravity: CGFloat = -0.4
//    private let jumpVelocity: CGFloat = 8.0
//    private let groundY: CGFloat = 0  // Dino's baseline
//    private let obstacleSpeed: CGFloat = 4
//    private let spawnInterval: Int = 120 // frames
//    
//    // MARK: - Dino Physics
//    private var dinoVelocity: CGFloat = 0
//    
//    // MARK: - Timer (Game Loop)
//    let timer = Timer
//        .publish(every: 1.0/60.0, // ~60 FPS
//                 on: .main,
//                 in: .common)
//        .autoconnect()
//    private var frameCount: Int = 0
//    
//    init() {
//        startGame()
//    }
//    
//    // MARK: - Start / Restart
//    func startGame() {
//        isGameOver = false
//        dinoY = 0
//        dinoVelocity = 0
//        obstacles = []
//        frameCount = 0
//    }
//    
//    // MARK: - Dino Jump
//    func jump() {
//        guard dinoY == groundY else { return } // Only jump if on ground
//        dinoVelocity = jumpVelocity
//    }
//    
//    // MARK: - Game Update (called ~60 times / second)
//    func updateGame() {
//        guard !isGameOver else { return }
//        
//        // 1) Update Dino position
//        dinoVelocity += gravity
//        dinoY += dinoVelocity
//        if dinoY < groundY {
//            dinoY = groundY
//            dinoVelocity = 0
//        }
//        
//        // 2) Spawn obstacles periodically
//        frameCount += 1
//        if frameCount % spawnInterval == 0 {
//            spawnObstacle()
//        }
//        
//        // 3) Move obstacles
//        for i in obstacles.indices {
//            obstacles[i].xPosition -= obstacleSpeed
//        }
//        
//        // 4) Remove off-screen obstacles
//        obstacles.removeAll { $0.xPosition < -100 }
//        
//        // 5) Check collisions
//        for obstacle in obstacles {
//            if checkCollision(obstacle: obstacle) {
//                isGameOver = true
//                break
//            }
//        }
//    }
//    
//    // MARK: - Obstacle Spawning
//    func spawnObstacle() {
//        let screenWidth = UIScreen.main.bounds.width
//        let size: CGFloat = CGFloat.random(in: 30...60) // random obstacle size
//        obstacles.append(Obstacle(
//            id: UUID(),
//            xPosition: screenWidth + size,
//            size: size
//        ))
//    }
//    
//    // MARK: - Collision Detection (Very simplistic box check)
//    func checkCollision(obstacle: Obstacle) -> Bool {
//        // Dino bounding box
//        let dinoLeft = UIScreen.main.bounds.width * 0.2 - 25
//        let dinoRight = UIScreen.main.bounds.width * 0.2 + 25
//        let dinoBottom = groundY
//        let dinoTop = dinoY + 50
//        
//        // Obstacle bounding box
//        let obsLeft = obstacle.xPosition - obstacle.size/2
//        let obsRight = obstacle.xPosition + obstacle.size/2
//        let obsBottom = groundY
//        let obsTop = obstacle.size
//        
//        let noOverlap = dinoRight < obsLeft ||
//                        dinoLeft > obsRight ||
//                        dinoTop < obsBottom ||
//                        dinoBottom > obsTop
//        
//        return !noOverlap
//    }
//}
