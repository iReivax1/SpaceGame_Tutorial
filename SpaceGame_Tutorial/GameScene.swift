//
//  GameScene.swift
//  SpaceGame_Tutorial
//
//  Created by Xavier on 1/1/19.
//  Copyright © 2019 Axus. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var StarField: SKEmitterNode!
    var Player: SKSpriteNode!
    var ScoreLabel: SKLabelNode!
    var Score: Int = 0{
        didSet{
            ScoreLabel.text = "Score: \(Score)"
        }
    }
    var gameTimer: Timer!
    var Aliens = ["alien", "alien2", "alien3"]
    
    let alienCategory: UInt32 = 0x1 << 1
    let torpedoCategory: UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAccelerator:CGFloat = 0
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        //SetUp background
        StarField = SKEmitterNode(fileNamed: "Starfield.sks")
        StarField.position = CGPoint(x:0 , y: view.frame.height)
        StarField.advanceSimulationTime(20)
        self.addChild(StarField)
        StarField.zPosition = -1
        
        //setup player
        Player = SKSpriteNode(imageNamed: "Spaceship.png")
        Player.position = CGPoint(x: 0, y: -(view.frame.height * 0.65))
        Player.scale(to: CGSize(width: 100  , height: 100))
        print("self.frame.size.height", view.frame.width)
        print("self.frame.size.width", view.frame.height)
        self.addChild(Player)
        
        //setupscoreboard
        ScoreLabel = SKLabelNode(text: "Score: 0")
        ScoreLabel.position = CGPoint(x: -(view.frame.width / 2)*0.75, y: view.frame.height*0.60)
        ScoreLabel.fontName = "HelveticaNeue-Light"
        ScoreLabel.fontColor = UIColor.white
        ScoreLabel.fontSize = 30
        self.addChild(ScoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        
        //Need indepth stuyd accelerometer use
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){
            (data: CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration =  accelerometerData.acceleration
                self.xAccelerator = CGFloat(acceleration.x) * 0.75 + self.xAccelerator*0.25
            }
        }
        
    }
    
    //need study
    func didBegin(_ contact: SKPhysicsContact){
        
        // bodyA is first body bodyB is second body(getting contacted)
        //categorybitmask is the attribute that will dictate if the object will interact with each other
        //let collision: UInt32 = contact.BodyA.categoryBitMask | contact.BodyB.categoryBitMask
        
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if(firstBody.categoryBitMask & torpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0{
            torpedoCollision(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
        
    }
    
    
    @objc func addAlien(){
        
        Aliens =  GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Aliens) as! [String]
        let Alien = SKSpriteNode(imageNamed: Aliens[0])
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: Int(-(view!.frame.width) - Alien.size.width), highestValue: Int((view!.frame.width) + Alien.size.width))
        let position = CGFloat(randomAlienPosition.nextInt())
        
        Alien.position = CGPoint(x:position, y: view!.frame.height + Alien.size.height)
        Alien.physicsBody = SKPhysicsBody(rectangleOf: Alien.size)
        Alien.physicsBody?.isDynamic = true
        
        // Need Help here
        Alien.physicsBody?.categoryBitMask = alienCategory
        Alien.physicsBody?.contactTestBitMask = torpedoCategory
        Alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(Alien)
        
        let randomDuration = GKRandomDistribution(lowestValue: 6, highestValue: 10)
        let animationDuration: TimeInterval = Double(randomDuration.nextInt())
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -view!.frame.height - Alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        Alien.run(SKAction.sequence(actionArray))
        
    }
    
  
    func torpedoCollision(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode){
        
        let explosion = SKEmitterNode(fileNamed: "Explosion.sks")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        torpedoNode.removeFromParent()
        
        //TODO : implement health system
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)){
            explosion.removeFromParent()
        }
        
        Score += 1
    }
    
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo.png")
        torpedoNode.position = Player.position
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = torpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.3
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: Player.position.x, y: view!.frame.height + torpedoNode.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
        print("torpedo cat", torpedoCategory)
        print("alien cat", alienCategory)
    }
    
    override func didSimulatePhysics() {
        
        Player.position.x += xAccelerator * 30
        
        //todo
    }
    

}
