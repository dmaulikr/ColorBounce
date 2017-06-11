//
//  MainScene.swift
//  ColorBounce
//
//  Created by Phil Javinsky III on 2/10/17.
//  Copyright © 2017 Phil Javinsky III. All rights reserved.
//

import SpriteKit
import GameKit

let defaults = UserDefaults.standard
var polygon: String = "hexagon"
var rotation: CGFloat = CGFloat(Double.pi/3)
var colors = ["red", "orange", "yellow", "green", "blue", "purple"]
var best = 0, hexagonBest = 0, heptagonBest = 0, octagonBest = 0, gravity = -13.0

class MainScene: SKScene, GKGameCenterControllerDelegate {
    private var touchLocation: CGPoint = CGPoint.zero
    private var axel: SKNode!
    private var start, scores, noAds: SKSpriteNode!
    private var hexagonButton, heptagonButton, octagonButton: SKSpriteNode!
    private var bestLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        start = self.childNode(withName: "start") as! SKSpriteNode
        hexagonButton = self.childNode(withName: "hexagonButton") as! SKSpriteNode
        heptagonButton = self.childNode(withName: "heptagonButton") as! SKSpriteNode
        octagonButton = self.childNode(withName: "octagonButton") as! SKSpriteNode
        scores = self.childNode(withName: "scores") as! SKSpriteNode
        noAds = self.childNode(withName: "noAds") as! SKSpriteNode
        axel = self.childNode(withName: polygon)
        axel.position = CGPoint(x: 0, y: 0)
        axel.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 6)))
        bestLabel = self.childNode(withName: "bestLabel") as! SKLabelNode
        
        // load local best scores
        hexagonBest = defaults.integer(forKey: "hexagonBest")
        heptagonBest = defaults.integer(forKey: "heptagonBest")
        octagonBest = defaults.integer(forKey: "octagonBest")
        
        perform(#selector(MainScene.getBestScores), with: nil, afterDelay: 3)
        
        if polygon == "hexagon" {
            best = hexagonBest
        }
        else if polygon == "heptagon" {
            best = heptagonBest
        }
        else if polygon == "octagon" {
            best = octagonBest
        }
        bestLabel.text = "Best: \(best)"
        
        adRemover.initialize()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = touches.first!.location(in: self)
        
        if start.contains(touchLocation) {
            let game = GameScene(fileNamed: "GameScene")!
            game.scaleMode = .aspectFit
            view?.presentScene(game, transition: .fade(with: .white, duration: 0.75))
        }
        else if hexagonButton.contains(touchLocation) && polygon != "hexagon" {
            polygon = "hexagon"
            rotation = CGFloat(Double.pi/3)
            colors = ["red", "orange", "yellow", "green", "blue", "purple"]
            gravity = -13.5
            reloadMain()
        }
        else if heptagonButton.contains(touchLocation) && polygon != "heptagon" {
            polygon = "heptagon"
            rotation = CGFloat(Double.pi/3.5)
            colors = ["red", "orange", "yellow", "green", "cyan", "blue", "purple"]
            gravity = -12.5
            reloadMain()
        }
        else if octagonButton.contains(touchLocation) && polygon != "octagon" {
            polygon = "octagon"
            rotation = CGFloat(Double.pi/4)
            colors = ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"]
            gravity = -11.5
            reloadMain()
        }
        else if scores.contains(touchLocation) {
            showLeaderboard()
        }
        else if noAds.contains(touchLocation) {
            let alert = UIAlertController.init(title: "Remove Ads", message: "Remove ads or restore a previous purchase.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Remove Ads", style: .default, handler:
                { action -> Void in
                    //print("Remove Ads")
                    adRemover.removeAds()
            }))
            alert.addAction(UIAlertAction(title: "Restore Purchase", style: .default, handler:
                { action -> Void in
                    //print("Restore purchase")
                    adRemover.restoreAdRemoval()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func reloadMain() {
        let main = MainScene(fileNamed: "MainScene")!
        main.scaleMode = .aspectFit
        view?.presentScene(main) //, transition: .fade(with: .white, duration: 0.5))
    }
    
    func moveUp(sprite: SKSpriteNode) {
        let up = SKAction.moveBy(x: 0, y: 1100, duration: 0.75)
        let down = SKAction.moveBy(x: 0, y: -50, duration: 0.2)
        let seq = SKAction.sequence([up, down])
        sprite.run(seq)
    }
    
    /* Game Center functions */
    func getBestScores() {
        if player.isAuthenticated {
            
            // compare local high scores with Game Center high scores
            if hexagonBest >= hexagonGC { // local score equal or better
                saveHighScore(hexagonBest, id: "hexagon")
            }
            else { // GC score better
                hexagonBest = hexagonGC
                defaults.set(hexagonBest, forKey: "hexagonBest")
            }
            
            if heptagonBest >= heptagonGC { // local score equal or better
                saveHighScore(heptagonBest, id: "heptagon")
            }
            else {
                heptagonBest = heptagonGC
                defaults.set(heptagonBest, forKey: "heptagonBest")
            }
            
            if octagonBest >= octagonGC { // local score equal or better
                saveHighScore(octagonBest, id: "octagon")
            }
            else {
                octagonBest = octagonGC
                defaults.set(octagonBest, forKey: "octagonBest")
            }
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
    
    // send high score to leaderboard
    func saveHighScore(_ highScore: Int, id: String) {
        // check if user is signed in
        if GKLocalPlayer.localPlayer().isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: id)
            scoreReporter.value = Int64(highScore)
            let scoreArray: [GKScore] = [scoreReporter]
            GKScore.report(scoreArray, withCompletionHandler: {(error: Error?) -> Void in
                if error != nil {
                    print("error")
                }
            })
        }
    }
}
