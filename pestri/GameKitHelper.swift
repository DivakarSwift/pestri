import GameKit

protocol GameKitHelperDelegate {
    func matchStarted()
    func matchEnded()
    func match(match: GKMatch, didReceiveData: NSData, fromPlayer: GKPlayer)
}

class GameKitHelper: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    var _enableGameCenter: Bool = true
    var _authenticationViewController: UIViewController?
    var _lastError: NSError?
    var _leaderboardIdentifier: String?
    
    var _matchStarted: Bool = false
    var _match: GKMatch?
    var _isServer = false
    var _serverPlayer: GKPlayer?
    var _delegate: GameKitHelperDelegate?
    
    static let PresentAuthenticationViewController = "present_authentication_view_controller"
    static let LocalPlayerIsAuthenticated = "local_player_authenticated"
    
    static let sharedInstance = GameKitHelper()
    private override init() {}
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        if localPlayer.authenticated {
            NSNotificationCenter.defaultCenter().postNotificationName(GameKitHelper.LocalPlayerIsAuthenticated, object:nil)
            return
        }
        
        localPlayer.authenticateHandler = self.authenticateHandler
    }
    
    private func authenticateHandler(viewController: UIViewController?, error: NSError?) {
        self.setLastError(error)
        
        if viewController != nil {
            _authenticationViewController = viewController
            NSNotificationCenter.defaultCenter().postNotificationName(GameKitHelper.PresentAuthenticationViewController, object: self)
        } else if GKLocalPlayer.localPlayer().authenticated {
            _enableGameCenter = true
            NSNotificationCenter.defaultCenter().postNotificationName(GameKitHelper.LocalPlayerIsAuthenticated, object:nil)
            GKLocalPlayer.localPlayer().loadDefaultLeaderboardIdentifierWithCompletionHandler({
                (leaderboardIdentifier: String?, error: NSError?) in
                if error != nil {
                    print(error)
                } else {
                    self._leaderboardIdentifier = leaderboardIdentifier
                }
            })
        } else {
            _enableGameCenter = false
        }
    }
    
    private func setLastError(error: NSError?) {
        if (error) != nil {
            _lastError = error!.copy() as? NSError
            print(_lastError)
        }
    }
    
    func findMatchWithMinPlayers(minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate: GameKitHelperDelegate) {
            
        if !_enableGameCenter {
           return
        }
            
        _matchStarted = false
        _match = nil;
        _delegate = delegate;
        viewController.dismissViewControllerAnimated(false, completion: nil)
            
        let request = GKMatchRequest.init()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
            
        let mmvc = GKMatchmakerViewController.init(matchRequest: request)
        mmvc!.matchmakerDelegate = self
            
        viewController.presentViewController(mmvc!, animated:true, completion:nil)
    }
    
    // The user has cancelled matchmaking
    func matchmakerViewControllerWasCancelled(viewController : GKMatchmakerViewController) {
        viewController.dismissViewControllerAnimated(true, completion:nil)
    }
    
    // Matchmaking has failed with an error
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFailWithError error: NSError) {
        viewController.dismissViewControllerAnimated(true, completion:nil)
        print("Error finding match: %@", error.localizedDescription)
    }
    
    // A peer-to-peer match has been found, the game should start
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindMatch match: GKMatch) {
        viewController.dismissViewControllerAnimated(true, completion:nil)
        _match = match
        match.delegate = self
        if !_matchStarted && match.expectedPlayerCount == 0 {
            print("Ready to start match!")
            startMatch()
        }
    }
    
    // The match received data sent from the player.
    func match(match: GKMatch, didReceiveData data: NSData, fromRemotePlayer player: GKPlayer) {
        if _match != match {
            return
        }
    
        _delegate!.match(match, didReceiveData: data, fromPlayer: player)
    }
    
    // The player state changed (eg. connected or disconnected)
    func match(match: GKMatch, player: GKPlayer, didChangeConnectionState state: GKPlayerConnectionState) {
        if _match != match {
            return
        }
    
        switch (state) {
            case GKPlayerConnectionState.StateConnected:
                // handle a new player connection.
                print("Player connected!")
    
                if (!_matchStarted && match.expectedPlayerCount == 0) {
                    print("Ready to start match!")
                    startMatch()
                }
    
                break;
            case GKPlayerConnectionState.StateDisconnected:
                // a player just disconnected.
                print("Player disconnected!")
                _matchStarted = false
                _delegate!.matchEnded()
                break;
            default:
                print("Player unknown status!")
            
        }
    }
    
    func startMatch() {
        _match!.chooseBestHostingPlayerWithCompletionHandler({
            (player) in
            self._matchStarted = true
            if player == GKLocalPlayer.localPlayer() {
                print("I am the server")
                self._isServer = true
            } else {
                print("I am a client")
                self._isServer = false
                self._serverPlayer = player
            }
            self._delegate!.matchStarted()
        })
    }

    
    // The match was unable to be established with any players due to an error.
    func match(match: GKMatch, didFailWithError error: NSError?) {
        if _match != match {
            return
        }
    
        print("Match failed with error: %@", error!.localizedDescription)
        _matchStarted = false
        _delegate!.matchEnded()
    }
    
    func reportScore(value: Int) {
        let score = GKScore.init(leaderboardIdentifier: _leaderboardIdentifier!)
        score.value = Int64(value)
        
        GKScore.reportScores([score], withCompletionHandler: {
            (error: NSError?) in
            if error != nil {
                print(error)
            }
        });
    }
    
    func showLeaderboardAndAchievements(viewController: UIViewController, gameCenterDelegate: GKGameCenterControllerDelegate, shouldShowLeaderboard: Bool) {
        let gcViewController = GKGameCenterViewController.init()
    
        gcViewController.gameCenterDelegate = gameCenterDelegate
    
        if (shouldShowLeaderboard) {
            gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
            gcViewController.leaderboardIdentifier = _leaderboardIdentifier
        } else {
            gcViewController.viewState = GKGameCenterViewControllerState.Achievements
        }
    
        viewController.presentViewController(gcViewController, animated:true, completion:nil)
    }
    
    func disconnect() {
        if _match != nil {
            _match?.disconnect()
        }
    }
}
