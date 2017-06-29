//
//  GameViewController.swift
//  ColorBounce
//
//  Created by Phil Javinsky III on 1/17/17.
//  Copyright © 2017 Phil Javinsky III. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import GoogleMobileAds
import GameKit

var bannerAd: GADBannerView = GADBannerView()
var interstitialAd: GADInterstitial!
var player = GKLocalPlayer.localPlayer()
var bestGC = 0
var adRemover = AdRemover()
var identifier = "colorBounceHighScore"

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticatePlayer()
        loadGCScore()
        
        createAndLoadBanner()
        createAndLoadInterstitial()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = MainScene(fileNamed: "MainScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }
    
    /* AdMob funtions */
    func createAndLoadBanner() {
        bannerAd.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.height/13) //top
        bannerAd.adUnitID = "ca-app-pub-6416730604045860/5452416908" //"ca-app-pub-3940256099942544/2934735716" // for test ads
        bannerAd.rootViewController = self
        
        let request = GADRequest()
        //request.testDevices = [kGADSimulatorID] // for simulator
        bannerAd.load(request)
        self.view.addSubview(bannerAd)
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        bannerAd.isHidden = true
    }
    
    func createAndLoadInterstitial() {
        interstitialAd = GADInterstitial(adUnitID: "ca-app-pub-6416730604045860/6929150102") // "ca-app-pub-3940256099942544/4411468910") // for test ads
        //interstitialAd.delegate = self
        interstitialAd.load(GADRequest())
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        createAndLoadInterstitial()
    }
    
    
    /* Game Center functions */
    func authenticatePlayer() {
        player.authenticateHandler = {(viewController, error) -> Void in
            // present sign in screen if device doesn't have an authenticated player
            if viewController != nil {
                self.present(viewController!, animated: true, completion: nil)
            }
        }
    }
    // load high scores from Game Center
    func loadGCScore() {
        let leaderboardRequest = GKLeaderboard()
        leaderboardRequest.identifier = identifier
        leaderboardRequest.loadScores { (scores, error) -> Void in
            if error != nil {
                print("Error: \(String(describing: error)))")
            }
            else if leaderboardRequest.localPlayerScore != nil {
                let leaderboardScore = leaderboardRequest.localPlayerScore!.value
                bestGC = Int(leaderboardScore)
            }
            else {
                bestGC = 0
            }
        }
    }
    
    /* Default functions */

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
