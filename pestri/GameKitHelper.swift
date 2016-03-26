import GameKit

class GameKitHelper: NSObject {
    var _enableGameCenter: Bool = true
    var _authenticationViewController: UIViewController?
    var _lastError: NSError?
    
    static let PresentAuthenticationViewController = "present_authentication_view_controller"
    
    static let sharedInstance = GameKitHelper()
    private override init() {}
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = self.authenticateHandler
    }
    
    private func authenticateHandler(viewController: UIViewController?, error: NSError?) {
        self.setLastError(error)
        
        if viewController != nil {
            _authenticationViewController = viewController
            NSNotificationCenter.defaultCenter().postNotificationName(GameKitHelper.PresentAuthenticationViewController, object: self)
        } else if GKLocalPlayer.localPlayer().authenticated {
            _enableGameCenter = true
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
}
