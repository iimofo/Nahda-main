//
//  DinoView.swift
//  Nahda
//
//  Created by mofo on 31.12.2024.
//
import SwiftUI

struct DinoView: View {
    let yPosition: CGFloat
    
    var body: some View {
        // Simple rectangle representing the dino
        Rectangle()
            .fill(Color.blue)
            .frame(width: 50, height: 50)
    }
}

struct ObstacleView: View {
    let xPosition: CGFloat
    let size: CGFloat
    
    var body: some View {
        // Simple rectangle representing an obstacle (cactus)
        Rectangle()
            .fill(Color.green)
            .frame(width: size, height: size)
    }
}

// MARK: - Obstacle Model
struct Obstacle: Identifiable {
    let id: UUID
    var xPosition: CGFloat
    let size: CGFloat
}

