import UIKit

class GameNavigationController: UINavigationController {
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameNavigationController.showAuthenticationViewController), name: GameKitHelper.PresentAuthenticationViewController, object: nil)
        
        GameKitHelper.sharedInstance.authenticateLocalPlayer()
    }
    
    func showAuthenticationViewController() {
        let gameKitHelper = GameKitHelper.sharedInstance
        self.topViewController?.presentViewController(gameKitHelper._authenticationViewController!, animated: true, completion: nil)
    }
}
