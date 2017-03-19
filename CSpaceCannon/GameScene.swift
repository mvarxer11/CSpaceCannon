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

class GameScene: SKScene ,SKPhysicsContactDelegate{
    
    var userDefaults:UserDefaults?
    let keyTopScore = "TopScore"
    var topScore = 0
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
        self.physicsWorld.contactDelegate = self
        
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
        
        // Spawn halos
        let spawnHaloAction = SKAction.sequence([SKAction.wait(forDuration: 0.5, withRange: 1), SKAction.perform(#selector(spawnHalo), onTarget: self)])
        self.run(SKAction.repeatForever(spawnHaloAction))

        
        // Restore ammo
        self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.2),
                SKAction.run{
                    self.ammo += 1
                    self.setAmmo(ammo: self.ammo)
                }
            ])))
        
        gameOver = true
        ammo = 5
        score = 0
        scoreLabel?.isHidden = true
        
        //Load top Score
        userDefaults = UserDefaults.standard
        topScore = (userDefaults?.integer(forKey: keyTopScore))!
        
    }
    
    func setScore(score:Int) {
        (menuLayer?.childNode(withName: "menuScoreLabel") as! SKLabelNode).text = String(score)
    }
    func setTopScore(topScore:Int) {
        (menuLayer?.childNode(withName: "menuBestLabel") as! SKLabelNode).text = String(topScore)
    }
    
    
    func newGame() {
        mainLayer?.removeAllChildren()
        menuLayer?.isHidden = true
        scoreLabel?.isHidden = false
        
        gameOver = false
        ammo = 5
        score = 0
        
        //add shields
        for i in 0...6 {
            let shield = SKSpriteNode.init(imageNamed: "Block")
            shield.name = "shield"
            shield.xScale = 2
            shield.yScale = 2
            shield.position = CGPoint(x: 75 + 100*i, y: 150)
            mainLayer?.addChild(shield)
            shield.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 42, height: 9))
            shield.physicsBody?.categoryBitMask = shieldCategory
            shield.physicsBody?.collisionBitMask = 0
        }
        
        //add lifeBar
        let lifeBar = SKSpriteNode.init(imageNamed: "BlueBar")
        lifeBar.position = CGPoint(x: self.size.width * 0.5, y: 120)
        lifeBar.size = CGSize(width: self.size.width, height: lifeBar.size.height)
        lifeBar.xScale = 2
        lifeBar.yScale = 2
        lifeBar.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x:-lifeBar.size.width/2,y:0), to: CGPoint(x: lifeBar.size.width/2, y: 0))
        lifeBar.physicsBody?.categoryBitMask = lifeBarCategory
        lifeBar.physicsBody?.collisionBitMask = 0
        mainLayer?.addChild(lifeBar)
        

        

    }
    
    func spawnHalo() {
        
        let halo = SKSpriteNode(imageNamed: "Halo")
        halo.name = "halo"
        halo.position = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width-halo.size.width)))+halo.size.width, y: self.size.height)
        halo.xScale = 2
        halo.yScale = 2
        halo.physicsBody = SKPhysicsBody(circleOfRadius: 32.0)
        
        guard (halo.physicsBody != nil) else { return }
        
        let direction = radiansToVector(radians: randomInRange(low: HaloLowAngle, high: HaloHighAngle))
        halo.physicsBody?.velocity.dx = direction.dx * HaloSpeed
        halo.physicsBody?.velocity.dy = direction.dy * HaloSpeed
        halo.physicsBody?.restitution = 1.0
        halo.physicsBody?.linearDamping = 0.0
        halo.physicsBody?.friction = 0.0
        halo.physicsBody?.categoryBitMask = haloCategory
        halo.physicsBody?.collisionBitMask = edgeCategory
        halo.physicsBody?.contactTestBitMask = ballCategory | shieldCategory | lifeBarCategory
        
        mainLayer?.addChild(halo)
        
    }
    
    
    //setAmmo
    func setAmmo(ammo:Int) {
        if (ammo >= 0 && ammo <= 5 ) {
            ammoDisplay?.texture = SKTexture(imageNamed: String.init(format: "Ammo%d", ammo))
        }
        scoreLabel?.text = String.init(format: "Score:%d", score)
    }
    
    //shoot
    func shoot (){

        guard self.ammo > 0 else { return }
        guard let cannon = self.cannon else { return }
        self.ammo -= 1
        setAmmo(ammo: self.ammo)
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
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.collisionBitMask = edgeCategory
        ball.physicsBody?.contactTestBitMask = edgeCategory
        
        mainLayer?.addChild(ball)
        
        //creat trail
        let ballTrailPath = Bundle.main.path(forResource: "BallTrail", ofType: "sks")
        let ballTrail:SKEmitterNode = NSKeyedUnarchiver.unarchiveObject(withFile: ballTrailPath!) as! SKEmitterNode
        ballTrail.targetNode = mainLayer
        ball.addChild(ballTrail)
        
     
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
    

    
    
    //代理方法
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody?
        var secondBody : SKPhysicsBody?
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == ballCategory) {
            self.addExplosion(position: (firstBody?.node?.position)!, name : "HaloExplosion")
            self.run(SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false))
            self.score += 1
            firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == shieldCategory) {
            
            self.addExplosion(position: (firstBody?.node?.position)!, name : "HaloExplosion")
            self.run(SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false))
            firstBody?.node?.removeFromParent()
            secondBody?.node?.removeFromParent()
        }
        
        if (firstBody?.categoryBitMask == haloCategory && secondBody?.categoryBitMask == lifeBarCategory) {
            self.addExplosion(position: (firstBody?.node?.position)!, name : "LifeBarExplosion")
            self.run(SKAction.playSoundFileNamed("DeepExplosion.caf", waitForCompletion: false))
            secondBody?.node?.removeFromParent()
            endGame()
        }
        
        if (firstBody?.categoryBitMask == ballCategory && secondBody?.categoryBitMask == edgeCategory) {
            self.addExplosion(position: contact.contactPoint, name : "BounceExplosion")
            self.run(SKAction.playSoundFileNamed("Bounce.caf", waitForCompletion: false))

        }

    }
    
    
    func endGame() {
        mainLayer?.enumerateChildNodes(withName: "halo", using: {
            (node,stop) in
            self.addExplosion(position: node.position, name: "HaloExplosion")
            node.removeFromParent()
        })
        mainLayer?.enumerateChildNodes(withName: "ball", using: {
            (node,stop) in
            node.removeFromParent()
        })
        mainLayer?.enumerateChildNodes(withName: "shield", using: {
            (node,stop) in
            node.removeFromParent()
        })
        
        setScore(score: score)
        if score > topScore {
            topScore = score
            userDefaults?.set(topScore, forKey: keyTopScore)
            userDefaults?.synchronize()
        }
        
        setTopScore(topScore: topScore)
        
        gameOver = true
        menuLayer?.isHidden = false
        scoreLabel?.isHidden = true
        
    }
    

    
    //add Explosion
    func addExplosion(position:CGPoint,name:String) {
        guard let explosion = SKEmitterNode(fileNamed:name) else { return }
        explosion.position = position
        explosion.xScale = 2.0
        explosion.yScale = 2.0
        mainLayer?.addChild(explosion)
        explosion.run(SKAction.sequence([SKAction.wait(forDuration: 1.5),SKAction.removeFromParent()]))
    }
  
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !gameOver {
            didShoot = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {

            if gameOver {
                let nodes = menuLayer?.nodes(at: t.location(in: self))
                if (nodes?.count)! > 0 && nodes?[0].name == "play" {
                    self.newGame()
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
