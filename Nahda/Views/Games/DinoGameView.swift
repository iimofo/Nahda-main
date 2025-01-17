//
//  DinoGameView.swift
//  Nahda
//
//  Created by mofo on 31.12.2024.
//
import SwiftUI
import SpriteKit

struct DinoGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameState = DinoGameState()
    
    var body: some View {
        ZStack {
            // Game Scene
            SpriteView(scene: gameState.scene)
                .ignoresSafeArea()
                // Add tap gesture for jumping
                .onTapGesture {
                    gameState.jump()
                }
            
            // Game UI Overlay
            VStack {
                // Top Bar
                HStack {
                    // Close Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Score Display
                    ScoreView(score: gameState.score)
                }
                
                Spacer()
                
                // Game Over Overlay
                if gameState.isGameOver {
                    GameOverView(
                        score: gameState.score,
                        highScore: gameState.highScore,
                        onRestart: { gameState.restartGame() }
                    )
                }
                
                // Hint text for new players
                if !gameState.isGameOver && gameState.score == 0 {
                    Text("Tap anywhere to jump!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ScoreView: View {
    let score: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("\(score)")
                .font(.title2.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
        .padding()
    }
}

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                Text("Score: \(score)")
                    .font(.title2)
                if score >= highScore && highScore > 0 {
                    Text("New High Score! 🎉")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
            }
            
            Button(action: onRestart) {
                Text("Play Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

// MARK: - Game Logic
class DinoGameState: ObservableObject {
    @Published var score: Int = 0
    @Published var highScore: Int = UserDefaults.standard.integer(forKey: "DinoHighScore")
    @Published var isGameOver = false
    
    let scene: DinoGameScene
    
    init() {
        scene = DinoGameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .black
        scene.gameDelegate = self
    }
    
    func jump() {
        scene.jump()
    }
    
    func duck() {
        scene.duck()
    }
    
    func restartGame() {
        isGameOver = false
        score = 0
        scene.restartGame()
    }
}

// MARK: - Game Scene
class DinoGameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameDelegate: DinoGameState?
    
    private var dino: SKSpriteNode!
    private var ground: SKSpriteNode!
    private var obstacles: [SKSpriteNode] = []
    
    // Physics Categories
    private let dinoCategory: UInt32 = 0x1 << 0
    private let groundCategory: UInt32 = 0x1 << 1
    private let obstacleCategory: UInt32 = 0x1 << 2
    
    // Update jump physics constants
    private let jumpForce: CGFloat = 800  // Increased for better jump feel
    private let maxJumpVelocity: CGFloat = 1000
    private let jumpCooldown: TimeInterval = 0.1
    private var canJump = true
    
    // Add ground movement properties
    private var groundSpeed: CGFloat = 400
    private var groundNodes: [SKSpriteNode] = []
    private let groundHeight: CGFloat = 2
    private let groundY: CGFloat = 200  // Fixed ground height
    
    // Update obstacle management properties
    private var lastObstacleTime: TimeInterval = 0
    private let minObstacleSpacing: TimeInterval = 1.5
    private let maxObstacleSpacing: TimeInterval = 2.5
    private var gameSpeed: CGFloat = 400
    
    override func didMove(to view: SKView) {
        setupPhysicsWorld()
        setupGround()
        setupDino()
        startGame()
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)  // Increased gravity for snappier jumps
        physicsWorld.contactDelegate = self
        
        // Add world bounds
        let frame = SKPhysicsBody(edgeLoopFrom: self.frame)
        frame.friction = 0
        frame.restitution = 0
        self.physicsBody = frame
    }
    
    private func setupGround() {
        // Create two ground pieces for infinite scrolling
        let groundWidth = frame.width * 1.5
        
        for i in 0...1 {
            let ground = SKSpriteNode(color: .gray, size: CGSize(width: groundWidth, height: groundHeight))
            ground.position = CGPoint(x: groundWidth * CGFloat(i), y: groundY)
            ground.anchorPoint = CGPoint(x: 0, y: 0.5)  // Set anchor to left center
            
            let physicsBody = SKPhysicsBody(rectangleOf: ground.size)
            physicsBody.isDynamic = false
            physicsBody.categoryBitMask = groundCategory
            physicsBody.collisionBitMask = dinoCategory
            ground.physicsBody = physicsBody
            
            addChild(ground)
            groundNodes.append(ground)
        }
    }
    
    private func setupDino() {
        dino = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 60))
        // Keep dino at fixed x position
        let dinoX = frame.width * 0.2
        dino.position = CGPoint(x: dinoX, y: groundY + groundHeight + dino.size.height/2)
        
        let physicsBody = SKPhysicsBody(rectangleOf: dino.size)
        physicsBody.mass = 1.0
        physicsBody.restitution = 0
        physicsBody.allowsRotation = false
        physicsBody.linearDamping = 0.8
        physicsBody.categoryBitMask = dinoCategory
        physicsBody.collisionBitMask = groundCategory
        physicsBody.contactTestBitMask = obstacleCategory
        dino.physicsBody = physicsBody
        
        addChild(dino)
    }
    
    func jump() {
        guard canJump, let physicsBody = dino.physicsBody else { return }
        
        // Only allow jumping if close to ground
        if abs(physicsBody.velocity.dy) < 10 {
            canJump = false
            
            // Apply jump force with better animation
            let jumpAction = SKAction.group([
                SKAction.run { [weak self] in
                    physicsBody.velocity = CGVector(dx: 0, dy: self?.jumpForce ?? 800)
                },
                SKAction.sequence([
                    SKAction.scaleY(to: 1.3, duration: 0.1),
                    SKAction.scaleY(to: 1.0, duration: 0.1)
                ])
            ])
            
            dino.run(jumpAction)
            
            // Reset jump after cooldown
            DispatchQueue.main.asyncAfter(deadline: .now() + jumpCooldown) { [weak self] in
                self?.canJump = true
            }
        }
    }
    
    func duck() {
        // Implement ducking animation and collision box adjustment
    }
    
    private func spawnObstacle() {
        // Randomly choose obstacle type
        let obstacleType = Int.random(in: 0...2)
        var obstacle: SKSpriteNode
        
        switch obstacleType {
        case 0: // Short obstacle
            obstacle = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 40))
        case 1: // Tall obstacle
            obstacle = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 60))
        default: // Wide obstacle
            obstacle = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 30))
        }
        
        // Position obstacle at the right edge of the screen
        obstacle.position = CGPoint(x: frame.width + obstacle.size.width/2,
                                  y: groundY + obstacle.size.height/2)
        
        let physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = obstacleCategory
        physicsBody.contactTestBitMask = dinoCategory
        obstacle.physicsBody = physicsBody
        
        addChild(obstacle)
        obstacles.append(obstacle)
        
        // Move obstacle
        let moveAction = SKAction.sequence([
            SKAction.moveBy(x: -(frame.width + obstacle.size.width), y: 0, duration: 2.0),
            SKAction.removeFromParent()
        ])
        
        obstacle.run(moveAction) { [weak self] in
            if let index = self?.obstacles.firstIndex(of: obstacle) {
                self?.obstacles.remove(at: index)
                self?.gameDelegate?.score += 1
            }
        }
    }
    
    func startGame() {
        gameSpeed = 400
        lastObstacleTime = 0
        
        // Start continuous obstacle spawning
        let spawnAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.spawnObstacle()
            },
            SKAction.wait(forDuration: 2.0)
        ])
        
        run(SKAction.repeatForever(spawnAction), withKey: "spawnObstacles")
    }
    
    func restartGame() {
        // Clean up existing obstacles
        obstacles.forEach { $0.removeFromParent() }
        obstacles.removeAll()
        
        // Reset dino position
        dino.position = CGPoint(x: frame.width * 0.2,
                              y: groundY + groundHeight + dino.size.height/2)
        dino.physicsBody?.velocity = .zero
        
        // Reset game state
        gameSpeed = 400
        lastObstacleTime = 0
        
        // Start spawning obstacles
        startGame()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == obstacleCategory ||
           contact.bodyB.categoryBitMask == obstacleCategory {
            gameOver()
        }
    }
    
    private func gameOver() {
        removeAction(forKey: "spawnObstacles")
        gameDelegate?.isGameOver = true
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Move ground pieces
        for ground in groundNodes {
            ground.position.x -= gameSpeed * CGFloat(1/60)
            
            if ground.position.x <= -ground.size.width {
                ground.position.x = ground.size.width
            }
        }
        
        // Keep dino at fixed x position
        if let physicsBody = dino.physicsBody {
            dino.position.x = frame.width * 0.2
            physicsBody.velocity.dx = 0
            
            if physicsBody.velocity.dy < -800 {
                physicsBody.velocity.dy = -800
            }
        }
    }
}

// Add protocol for better type safety
protocol DinoGameDelegate: AnyObject {
    var score: Int { get set }
    var isGameOver: Bool { get set }
}

// Make DinoGameState conform to the protocol
extension DinoGameState: DinoGameDelegate {}

struct DinoGameView_Previews: PreviewProvider {
    static var previews: some View {
        DinoGameView()
    }
}

