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
var best = 0

class MainScene: SKScene, GKGameCenterControllerDelegate {
    private var touchLocation: CGPoint = CGPoint.zero
    private var axel: SKNode!
    private var start, scores, noAds, rate: SKSpriteNode!
    private var bestLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        start = self.childNode(withName: "start") as! SKSpriteNode
        scores = self.childNode(withName: "scores") as! SKSpriteNode
        noAds = self.childNode(withName: "noAds") as! SKSpriteNode
        rate = self.childNode(withName: "rate") as! SKSpriteNode
        axel = self.childNode(withName: "octagon")
        axel.position = CGPoint(x: 0, y: 0)
        axel.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 6)))
        bestLabel = self.childNode(withName: "bestLabel") as! SKLabelNode
        
        // load local best score
        best = defaults.integer(forKey: "best")
        
        
        perform(#selector(MainScene.getBestScores), with: nil, afterDelay: 3)
        
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
        else if rate.contains(touchLocation) {
            let url = NSURL(string: "itms-apps://itunes.apple.com/us/app/color-wheel-spin-to-win/id1245973948?ls=1&mt=8")
            
            if UIApplication.shared.canOpenURL(url! as URL) {
                UIApplication.shared.openURL(url! as URL)
            }
        }
    }
    
    /* Game Center functions */
    func getBestScores() {
        if player.isAuthenticated {
            
            // compare local high scores with Game Center high scores
            if best >= bestGC { // local score equal or better
                saveHighScore(best)
            } else { // GC score better
                best = bestGC
                defaults.set(best, forKey: "best")
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
    func saveHighScore(_ highScore: Int) {
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
}
