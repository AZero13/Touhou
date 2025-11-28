# Touhou (Swift/macOS)

A native macOS implementation of a Touhou-style Bullet Hell game, built with Swift, SpriteKit, and GameplayKit.

## Overview

This project demonstrates a high-performance 2D game engine using Apple's native technologies. It features a custom Entity-Component-System (ECS) architecture for managing game logic, rendering, and physics.

### Key Features
- **ECS Architecture**: Decoupled logic using GameplayKit's `GKEntity` and `GKComponent`.
- **SpriteKit Rendering**: High-performance 2D rendering.
- **Bullet Hell Mechanics**: Complex bullet patterns, grazing, and boss phases.
- **Dialogue System**: Scriptable dialogue sequences.

## Getting Started

### Prerequisites
- macOS 13.0+
- Xcode 14.0+

### Building and Running
1.  Open `Touhou.xcodeproj` in Xcode.
2.  Select the `Touhou` scheme.
3.  Press `Cmd + R` to build and run.

## Architecture

The project follows a strict ECS pattern:

- **Entities**: Composition of components (e.g., `Player`, `Enemy`, `Bullet`).
- **Components**: Data containers (e.g., `TransformComponent`, `VelocityComponent`, `RenderComponent`).
- **Systems**: Logic processors that operate on entities with specific components (e.g., `MovementSystem`, `RenderSystem`, `CollisionSystem`).

### Key Directories
- `Core/`: Fundamental types and the `GameFacade` singleton.
- `Components/`: All `GKComponent` definitions.
- `Systems/`: Logic systems that update every frame.
- `GameScene.swift`: The main SpriteKit scene handling the view layer.

## Controls
- **Arrow Keys**: Move
- **Z**: Shoot / Confirm
- **X**: Bomb / Cancel
- **Shift**: Focus Mode (Slow movement)
