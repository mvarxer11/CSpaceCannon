//
//  GameScene.swift
//  CSpaceCannon
//
//  Created by mvarxer on 17/3/15.
//  Copyright © 2017年 mvarxer. All rights reserved.
//

import SpriteKit
import GameplayKit

func radiansToVector(radians:CGFloat)->CGVector {
    var vector = CGVector()
    vector.dx = cos(radians)
    vector.dy = sin(radians)
    return vector
}

func randomInRange(low : CGFloat, high : CGFloat) -> CGFloat{
    var value = CGFloat(arc4random_uniform(10000)) / CGFloat(10000)
    value = value * (high - low) + low
    return value
}

class GameScene: SKScene {
    
    let SHOOT_SPEED : CGFloat = 1000.0
    let HaloLowAngle : CGFloat = 200.0 * CGFloat.pi / 180.0
    let HaloHighAngle : CGFloat = 340.0 * CGFloat.pi / 180.0
    let HaloSpeed : CGFloat = 200.0
    let haloCategory : UInt32 = 0x1 << 0
    let ballCategory : UInt32 = 0x1 << 1
    let edgeCategory : UInt32 = 0x1 << 2
    let shieldCategory : UInt32 = 0x1 << 3
    let lifeBarCategory : UInt32 = 0x1 << 4
    var ammo = 5
    var score = 0
    var gameOver = true
    
    private var mainLayer : SKNode?
    private var menuLayer : SKNode?
    private var cannon : SKSpriteNode?
    private var ammoDisplay : SKSpriteNode?
    private var scoreLabel : SKLabelNode?
    //private var explosion : SKEmitterNode?
    private var didShoot = false
    
    
    
    
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        
        //self.explosion = SKEmitterNode(fileNamed: "HaloExplosion.sks")
        
        self.cannon = self.childNode(withName: "cannon") as? SKSpriteNode
        self.ammoDisplay = self.childNode(withName: "ammoDisplay") as? SKSpriteNode
        self.scoreLabel = self.childNode(withName: "scoreLabel") as? SKLabelNode
        self.mainLayer = self.childNode(withName: "mainLayer")
        self.menuLayer = self.childNode(withName: "menuLayer")
        
        // Add edges
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        leftEdge.physicsBody?.categoryBitMask = edgeCategory
        leftEdge.position = CGPoint(x: 0, y: 0)
        self.addChild(leftEdge)
        
        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: 0.0, y: self.size.height))
        rightEdge.physicsBody?.categoryBitMask = edgeCategory
        rightEdge.position = CGPoint(x: self.size.width, y: 0.0)
        self.addChild(rightEdge)


    }
    
    func shoot (){

        guard let cannon = self.cannon else { return }
        let ball = SKSpriteNode(imageNamed: "Ball")

        ball.name = "ball"
        let rotationVector = radiansToVector(radians: (cannon.zRotation))
        ball.position = CGPoint(x: (cannon.position.x + cannon.size.width * 0.5 * rotationVector.dx),
                                y: (cannon.position.y + cannon.size.height * 0.5 * rotationVector.dy))
        ball.xScale = 2
        ball.yScale = 2
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 12.0)
        ball.physicsBody?.velocity = CGVector(dx: rotationVector.dx*SHOOT_SPEED, dy: rotationVector.dy*SHOOT_SPEED)
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.friction = 0
        
        
        
        
        mainLayer?.addChild(ball)
        
        

        
    }
    
    override func didSimulatePhysics() {
        
        if didShoot {
            shoot()
            didShoot = false
        }
        
        mainLayer?.enumerateChildNodes(withName: "ball", using: {
            (node,stop) in
            if !self.frame.contains(node.position) {
                node.removeFromParent()
            }
            
        })
    }
  
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        didShoot = true
//        if !gameOver {
//            didShoot = true
//        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
