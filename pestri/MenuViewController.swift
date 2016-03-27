import UIKit
import GameKit

class MenuViewController: UIViewController, GameKitHelperDelegate, GKGameCenterControllerDelegate {
    @IBOutlet weak var multiplayerButton: UIButton!
    var _canStartMultiplayerGame = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "pattern")!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        multiplayerButton.enabled = _canStartMultiplayerGame
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerAuthenticated), name:GameKitHelper.LocalPlayerIsAuthenticated, object:nil)
    }
    
    func playerAuthenticated() {
        _canStartMultiplayerGame = true
        multiplayerButton.enabled = true
    }
    
    @IBAction func startMultiplayerGame(sender: AnyObject) {
        if !_canStartMultiplayerGame {
            return
        }
        let maxPlayers = GKMatchRequest.maxPlayersAllowedForMatchOfType(GKMatchType.PeerToPeer)
        GameKitHelper.sharedInstance.findMatchWithMinPlayers(2, maxPlayers:maxPlayers, viewController:self, delegate:self)
    }

    @IBAction func showLeaderboard(sender: AnyObject) {
        GameKitHelper.sharedInstance.showLeaderboardAndAchievements(self, gameCenterDelegate: self, shouldShowLeaderboard: false)
    }

    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion:nil)
    }
    
    func matchStarted() {
        performSegueWithIdentifier("startGame", sender: nil)
    }

    func matchEnded() {
        
    }

    func match(match: GKMatch, didReceiveData: NSData, fromPlayer: GKPlayer) {
        
    }
}
