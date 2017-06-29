//
//  GameScene.swift
//  ColorBounce
//
//  Created by Phil Javinsky III on 1/17/17.
//  Copyright © 2017 Phil Javinsky III. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit

let ballMask: UInt32 = 0x1 << 0 // 1
let platformMask: UInt32 = 0x1 << 1 // 2
let blockMask: UInt32 = 0x1 << 2 // 4
let centerMask: UInt32 = 0x1 << 3 // 8

var score = 0

class GameScene: SKScene, SKPhysicsContactDelegate, GKGameCenterControllerDelegate {
    private var touchLocation: CGPoint = CGPoint.zero
    private var ball, home, restart, scores, noAds, arrow: SKSpriteNode!
    private var scoreLabel, gameOverLabel, scoreLabel2, scoreText,
                bestLabel, bestText: SKLabelNode!
    private var ballColor = "", lastColor = "", blockColor = "", lastDir = "down"
    private var axel: SKNode!
    private var colors = ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"]
    private var rotation: CGFloat = CGFloat(Double.pi/4)
    private var index = 0, gravity = -9.8
    private var over = false
    private var gravVec = CGVector(dx: 0, dy: 300)
    
    override func didMove(to view: SKView) {
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        ball.physicsBody?.contactTestBitMask = platformMask | centerMask // | blockMask
        ball.physicsBody?.collisionBitMask = platformMask
        
        axel = self.childNode(withName: "octagon")
        axel.position = CGPoint(x: 0, y: 0)
        arrow = self.childNode(withName: "arrow") as! SKSpriteNode
        
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        home = self.childNode(withName: "home") as! SKSpriteNode
        restart = self.childNode(withName: "restart") as! SKSpriteNode
        restart.alpha = 0
        scores = self.childNode(withName: "scores") as! SKSpriteNode
        noAds = self.childNode(withName: "noAds") as! SKSpriteNode
        
        gameOverLabel = self.childNode(withName: "gameOverLabel") as! SKLabelNode
        scoreText = self.childNode(withName: "scoreText") as! SKLabelNode
        bestLabel = self.childNode(withName: "bestLabel") as! SKLabelNode
        bestText = self.childNode(withName: "bestText") as! SKLabelNode
        
        score = 0
        
        // random starting color
        blockColor = randomColor()
        ballColor = blockColor
        lastColor = ballColor
        ball.texture = SKTexture(imageNamed: ballColor)
        index = colors.index(of: blockColor)!
        axel.zRotation = CGFloat(index) * -rotation
        
        // drop ball
        self.physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
        let wait = SKAction.wait(forDuration: 1)
        let drop = SKAction.run({ self.ball.physicsBody?.affectedByGravity = true })
        
        let seq = SKAction.sequence([wait, drop])
        self.run(seq)
        
        self.physicsWorld.contactDelegate = self
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = touches.first!.location(in: self)
        
        if home.contains(touchLocation) {
            let main = MainScene(fileNamed: "MainScene")!
            main.scaleMode = .aspectFit
            view?.presentScene(main, transition: .fade(with: .white, duration: 0.75))
        }
        else if restart.contains(touchLocation) {
            let game = GameScene(fileNamed: "GameScene")!
            game.scaleMode = .aspectFit
            view?.presentScene(game, transition: .fade(with: .white, duration: 0.75))
        }
        else if scores.contains(touchLocation) {
            showLeaderboard()
        }
        else if noAds.contains(touchLocation) {
            let alert = UIAlertController.init(title: "Remove Ads", message: "Remove ads or restore a previous purchase.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Remove Ads", style: .default, handler:
                { action -> Void in
                    print("Remove Ads")
                    adRemover.removeAds()
            }))
            alert.addAction(UIAlertAction(title: "Restore Purchase", style: .default, handler:
                { action -> Void in
                    print("Restore purchase")
                    adRemover.restoreAdRemoval()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = touches.first!.location(in: self)
        
        if !over {
            if touchLocation.x >= 0 {
                axel.run(SKAction.rotate(byAngle: -rotation, duration: 0.1))
                if index == colors.count - 1 {
                    index = 0
                }
                else {
                    index += 1
                }
            }
            else if touchLocation.x < 0 {
                axel.run(SKAction.rotate(byAngle: rotation, duration: 0.1))
                if index == 0 {
                    index = colors.count - 1
                }
                else {
                    index -= 1
                }
            }
            blockColor = colors[index]
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let node = (contact.bodyA.categoryBitMask == ballMask) ? contact.bodyA : contact.bodyB
        let other = (node == contact.bodyA) ? contact.bodyB : contact.bodyA
        
        if other.categoryBitMask == platformMask {
            if blockColor == ballColor {
                score += 1
                scoreLabel.text = "\(score)"
                while self.lastColor == ballColor {
                    ballColor = randomColor()
                }
                lastColor = ballColor
                ball.texture = SKTexture(imageNamed: ballColor)
                
                let step1 = SKAction.run { // bounce up and rotate arrow
                    self.ball.physicsBody?.applyImpulse(self.gravVec)
                    self.rotateArrow()
                }
                let wait1 = SKAction.wait(forDuration: 0.8) // wait for ball to hit peak height
                let step2 = SKAction.run { // turn gravity off, stop ball at center, and change gravity direction
                    self.ball.physicsBody?.affectedByGravity = false
                    self.ball.physicsBody?.pinned = true
                    self.ball.position = CGPoint(x: 0, y:0)
                    self.changeGravity(dir: self.lastDir)
                }
                let wait2 = SKAction.wait(forDuration: 0.05) // wait at center for 0.25 sec
                let step3 = SKAction.run { // turn gravity on
                    self.ball.physicsBody?.pinned = false
                    self.ball.physicsBody?.affectedByGravity = true
                }
                let seq = SKAction.sequence([step1,wait1,step2,wait2,step3])
                self.run(seq)
                
                if lastDir == "up" {
                    gravVec = CGVector(dx: 0, dy: -300)
                }
                else if lastDir == "left" {
                    gravVec = CGVector(dx: 300, dy: 0)
                }
                else if lastDir == "right" {
                    gravVec = CGVector(dx: -300, dy: 0)
                }
                else { // down
                    gravVec = CGVector(dx: 0, dy: 300)
                }
                
            }
            else {
                // game over
                over = true
                gameOver()
            }
        }
    }
    
    // rotate arrow to random direction and adjust index
    func rotateArrow() {
        let num = arc4random_uniform(UInt32(4))
        var rotateTo = 0.0
        
        if num == 0 { // up
            rotateTo = Double.pi/2.0
            
            if lastDir == "down" {
                switch index {
                    case 0,1,2,3:
                        index += 4
                    case 4:
                        index = 0
                    case 5:
                        index = 1
                    case 6:
                        index = 2
                    case 7:
                        index = 3
                    default:
                        index = 0
                }
            }
            else if lastDir == "left" {
                switch index {
                    case 0:
                        index = 6
                    case 1:
                        index = 7
                    case 2,3,4,5,6,7:
                        index -= 2
                    default:
                        index = 0
                }
            }
            else if lastDir == "right" {
                switch index {
                    case 0,1,2,3,4,5:
                        index += 2
                    case 6:
                        index = 0
                    case 7:
                        index = 1
                    default:
                        index = 0
                }
            }
            lastDir = "up"
        }
        else if num == 1 { // left
            rotateTo = Double.pi
            
            if lastDir == "up" {
                switch index {
                    case 0,1,2,3,4,5:
                        index += 2
                    case 6:
                        index = 0
                    case 7:
                        index = 1
                    default:
                        index = 0
                }
            }
            else if lastDir == "down" {
                switch index {
                    case 0,1:
                        index += 6
                    case 2:
                        index = 0
                    case 3:
                        index = 1
                    case 4:
                        index = 2
                    case 5:
                        index = 3
                    case 6:
                        index = 4
                    case 7:
                        index = 5
                    default:
                        index = 0
                }
            }
            else if lastDir == "right" {
                switch index {
                    case 0,1,2,3:
                        index += 4
                    case 4:
                        index = 0
                    case 5:
                        index = 1
                    case 6:
                        index = 2
                    case 7:
                        index = 3
                    default:
                        index = 0
                }
            }
            lastDir = "left"
        }
        else if num == 2 { // right
            rotateTo = 0
            
            if lastDir == "up" {
                switch index {
                    case 0:
                        index = 6
                    case 1:
                        index = 7
                    case 2,3,4,5,6,7:
                        index -= 2
                    default:
                        index = 0
                }
            }
            else if lastDir == "left" {
                switch index {
                    case 0:
                        index = 4
                    case 1:
                        index = 5
                    case 2:
                        index = 6
                    case 3:
                        index = 7
                    case 4,5,6,7:
                        index -= 4
                    default:
                        index = 0
                }
            }
            else if lastDir == "down" {
                switch index {
                    case 0,1,2,3,4,5:
                        index += 2
                    case 6:
                        index = 0
                    case 7:
                        index = 1
                    default:
                        index = 0
                }
            }
            lastDir = "right"
        }
        else { // down
            rotateTo = (3 * Double.pi)/2.0
            
            if lastDir == "up" {
                switch index {
                case 0:
                    index = 4
                case 1:
                    index = 5
                case 2:
                    index = 6
                case 3:
                    index = 7
                case 4,5,6,7:
                    index -= 4
                default:
                    index = 0
                }
            }
            else if lastDir == "left" {
                switch index {
                case 0:
                    index = 2
                case 1:
                    index = 3
                case 2:
                    index = 4
                case 3:
                    index = 5
                case 4:
                    index = 6
                case 5:
                    index = 7
                case 6,7:
                    index -= 6
                default:
                    index = 0
                }
            }
            else if lastDir == "right" {
                switch index {
                case 0:
                    index = 6
                case 1:
                    index = 7
                case 2,3,4,5,6,7:
                    index -= 2
                default:
                    index = 0
                }
            }
            lastDir = "down"
        }
        
        blockColor = colors[index]
        arrow.run(SKAction.rotate(toAngle: CGFloat(rotateTo), duration: 0.2))
    }
    
    // change gravity direction depending on dir
    func changeGravity(dir: String) {
        var newGravity = CGVector(dx: 0, dy: -13.0)
        
        if dir == "up" { // up
            newGravity = CGVector(dx: 0, dy: -gravity)
        }
        else if dir == "left" { // left
            newGravity = CGVector(dx: gravity, dy: 0)
        }
        else if dir == "right" { // right
            newGravity = CGVector(dx: -gravity, dy: 0)
        }
        else { // down
            newGravity = CGVector(dx: 0, dy: gravity)
        }
        
        self.physicsWorld.gravity = newGravity
    }
    
    // returns a random color
    func randomColor() -> String {
        var color = "red"
        let num = arc4random_uniform(UInt32(8))
        
        switch num {
            case 0:
                color = "red"
            case 1:
                color = "orange"
            case 2:
                color = "yellow"
            case 3:
                color = "green"
            case 4:
                color = "cyan"
            case 5:
                color = "blue"
            case 6:
                color = "purple"
            case 7:
                color = "pink"
            default:
                color = "red"
        }
        return color
    }
    
    func gameOver() {
        if interstitialAd.isReady && !hideAds {
            interstitialAd.present(fromRootViewController: (self.view?.window?.rootViewController)!)
        }
        
        if score > best {
            best = score
            defaults.set(best, forKey: "best")
            if player.isAuthenticated {
                saveHighScore(highScore: best)
            }
        }
        
        explodeBall()
        arrow.removeFromParent()
        
        axel.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 6)))
        
        gameOverLabel.run(SKAction.moveTo(y: 550, duration: 0.75))
        
        scoreLabel.position = CGPoint(x: -700, y: -50)
        scoreLabel.fontSize = 125
        scoreLabel.run(SKAction.moveTo(x: -235, duration: 0.75))
        scoreText.run(SKAction.moveTo(x: -235, duration: 0.75))
        
        bestLabel.text = "\(best)"
        bestLabel.run(SKAction.moveTo(x: 235, duration: 0.75))
        bestText.run(SKAction.moveTo(x: 235, duration: 0.75))
        
        restart.position = CGPoint(x: 0, y: 0)
        restart.run(SKAction.fadeIn(withDuration: 2))
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.75)
        let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.75)
        let fade = SKAction.sequence([fadeOut, fadeIn])
        restart.run(SKAction.repeatForever(fade))
        
        moveUp(sprite: home, y: -550, sec: 0.75)
        moveUp(sprite: noAds, y: -450, sec: 0.75)
        moveUp(sprite: scores, y: -450, sec: 0.75)
    }
    
    func moveUp(sprite: SKSpriteNode, y: CGFloat, sec: TimeInterval) {
        let up = SKAction.moveTo(y: y + 50, duration: sec)
        let down = SKAction.moveTo(y: y, duration: 0.2)
        let seq = SKAction.sequence([up, down])
        sprite.run(seq)
    }
    
    func explodeBall() {
        let spark: SKEmitterNode = SKEmitterNode(fileNamed: "Spark")!
        var sparkColor = UIColor.black
        
        if ballColor == "red" {
            sparkColor = UIColor(red: 219/255, green: 0, blue: 0, alpha: 0.5)
        }
        else if ballColor == "orange" {
            sparkColor = UIColor(red: 1, green: 165/255, blue: 0, alpha: 0.5)
        }
        else if ballColor == "yellow" {
            sparkColor = UIColor(red: 1, green: 1, blue: 0, alpha: 0.5)
        }
        else if ballColor == "green" {
            sparkColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
        }
        else if ballColor == "blue" {
            sparkColor = UIColor(red: 4/255, green: 51/255, blue: 1, alpha: 0.5)
        }
        else if ballColor == "purple" {
            sparkColor = UIColor(red: 46/255, green: 0/255, blue: 79/255, alpha: 0.5)
        }
        else if ballColor == "cyan" {
            sparkColor = UIColor(red: 0, green: 1, blue: 1, alpha: 0.5)
        }
        else if ballColor == "pink" {
            sparkColor = UIColor(red: 1, green: 64/255, blue: 1, alpha: 0.5)
        }
        spark.particleColorSequence = nil
        spark.particleColor = sparkColor
        spark.position = ball.position
        self.addChild(spark)
        ball.removeFromParent()
    }
    
    
    /* Game Center functions */
    func saveHighScore(highScore: Int) {
        // check if user is signed in
        if GKLocalPlayer.localPlayer().isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: identifier)
            scoreReporter.value = Int64(highScore)
            let scoreArray: [GKScore] = [scoreReporter]
            GKScore.report(scoreArray, withCompletionHandler: {(error: Error?) -> Void in
                if error != nil {
                    print("error")
                }
            })
        }
    }
    
    // hide leaderboard screen, required by GKGameCenterControllerDelegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    // show leaderboard screen
    func showLeaderboard() {
        let vc = self.view?.window?.rootViewController
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        vc?.present(gc, animated: true, completion: nil)
    }
}
