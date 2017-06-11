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
let wheelMask: UInt32 = 0x1 << 2 // 4

var score = 0

class GameScene: SKScene, SKPhysicsContactDelegate, GKGameCenterControllerDelegate {
    private var touchLocation: CGPoint = CGPoint.zero
    private var ball, platform, home, restart, scores, noAds: SKSpriteNode!
    private var scoreLabel, gameOverLabel, scoreLabel2, scoreText,
                bestLabel, bestText: SKLabelNode!
    private var ballColor = "", lastColor = "", blockColor = ""
    private var axel: SKNode!
    private var index = 0
    private var started = false, over = false
    
    override func didMove(to view: SKView) {
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        ball.physicsBody?.contactTestBitMask = platformMask
        ball.physicsBody?.collisionBitMask = platformMask
        
        axel = self.childNode(withName: polygon)
        axel.position = CGPoint(x: 0, y: 0)
        
        platform = self.childNode(withName: "platform") as! SKSpriteNode
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
        lastColor = blockColor
        ball.texture = SKTexture(imageNamed: blockColor)
        index = colors.index(of: blockColor)!
        axel.zRotation = CGFloat(index) * -rotation
        
        // drop ball
        let wait = SKAction.wait(forDuration: 1)
        let drop = SKAction.run({ self.ball.physicsBody?.affectedByGravity = true })
        let seq = SKAction.sequence([wait, drop])
        self.run(seq)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
        self.physicsWorld.contactDelegate = self
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        let node = (contact.bodyA.categoryBitMask == ballMask) ? contact.bodyA : contact.bodyB
        let other = (node == contact.bodyA) ? contact.bodyB : contact.bodyA
        
        if other.categoryBitMask == platformMask {
            if blockColor == ballColor {
                ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
                score += 1
                scoreLabel.text = "\(score)"
                while lastColor == ballColor {
                    ballColor = randomColor()
                }
                lastColor = ballColor
                ball.texture = SKTexture(imageNamed: ballColor)
            }
            else {
                // game over
                // check if score > best, save and send to Game Center?
                over = true
                gameOver()
            }
        }
    }
    
    func randomColor() -> String {
        var color = "red"
        let num = arc4random_uniform(UInt32(colors.count))
        
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
                color = "blue"
            case 5:
                color = "purple"
            case 6:
                color = "cyan"
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
            if polygon == "hexagon" {
                defaults.set(best, forKey: "hexagonBest")
            }
            else if polygon == "heptagon" {
                defaults.set(best, forKey: "heptagonBest")
            }
            else if polygon == "octagon" {
                defaults.set(best, forKey: "octagonBest")
            }
            
            if player.isAuthenticated {
                saveHighScore(highScore: best)
            }
        }
        
        explodeBall()
        
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
        
        moveUp(sprite: home, y: -600, sec: 0.75)
        moveUp(sprite: noAds, y: -550, sec: 0.75)
        moveUp(sprite: scores, y: -550, sec: 0.75)
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
            let scoreReporter = GKScore(leaderboardIdentifier: polygon)
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
