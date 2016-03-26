import UIKit
import SpriteKit
import MultipeerConnectivity
import GameKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            let sceneData = try! NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate {
    var gameView : SKView!
    var scene : GameScene!
    
    // Multipeer part
    var browser : MCBrowserViewController!
    var advertiser : MCAdvertiserAssistant!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Game view set up
        self.gameView = SKView(frame: UIScreen.mainScreen().bounds)

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.gameView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            scene.size = skView.bounds.size
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
            
            self.scene = scene
            
            scene.parentView = self
        }
        self.view = gameView
        
        // Multipeer init
        self.browser = MCBrowserViewController(serviceType: "agario-ming", session: self.scene.session)
        self.browser.modalPresentationStyle = .FormSheet
        self.browser.maximumNumberOfPeers = 1
        self.browser.delegate = self
        self.advertiser = MCAdvertiserAssistant(serviceType: "agario-ming", discoveryInfo: nil, session: self.scene.session)
        self.advertiser.delegate = self
        
        self.startSingle()
    }
    
    func startSingle() {
        self.advertiser.stop()
        
        // Set Player Name
        self.scene.playerName = "Me"
        self.scene.start()
    }
    
    func startMultiple() {
        self.scene.playerName = GKLocalPlayer.localPlayer().alias!
        self.advertiser.stop()
        
        let alert = UIAlertController(title: "New Game or Existent Game", message: "Please make a decision", preferredStyle: .ActionSheet)
        let masterAction = UIAlertAction(title: "Start a New Game", style: .Default) { (action) in
            self.scene.start(GameScene.GameMode.MPMaster)
            self.advertiser.start()
            alert.dismissViewControllerAnimated(false, completion: { () -> Void in})
        }
        alert.addAction(masterAction)
        let clientAction = UIAlertAction(title: "Search & Join a Game", style: .Default) { [unowned self, browser = self.browser] (action) in
            self.presentViewController(browser, animated: true, completion: nil)
            alert.dismissViewControllerAnimated(false, completion: { () -> Void in})
        }
        alert.addAction(clientAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            alert.dismissViewControllerAnimated(false, completion: nil)
        }
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        self.scene.start(GameScene.GameMode.MPClient)
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        browser.session.disconnect()
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func checkMotionDetectStatus(mdswitch: UISwitch) {
        if mdswitch.on {
            self.scene.motionManager.startDeviceMotionUpdates()
            self.scene.motionDetectionIsEnabled = true
        } else {
            self.scene.motionManager.stopDeviceMotionUpdates()
            self.scene.motionDetectionIsEnabled = false
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}