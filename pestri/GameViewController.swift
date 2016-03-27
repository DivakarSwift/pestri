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

class GameViewController: UIViewController, GameKitHelperDelegate{
    var gameView : SKView!
    var scene : GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        GameKitHelper.sharedInstance._delegate = self
        
        // Game view set up
        self.gameView = SKView(frame: UIScreen.mainScreen().bounds)

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.gameView
    
            #if DEBUG
                skView.showsFPS = true
                skView.showsNodeCount = true
            #endif
            
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
        
        if GameKitHelper.sharedInstance._matchStarted {
            self.startMultiple()
        } else {
            self.startSingle()
        }
        
    }
    
    func startSingle() {
        // Set Player Name
        if GKLocalPlayer.localPlayer().alias != nil {
            self.scene.playerName = GKLocalPlayer.localPlayer().alias!
        } else {
            self.scene.playerName = "Me"
        }
        self.scene.start(GameScene.GameMode.Offline)
    }
    
    func startMultiple() {
        self.scene.playerName = GKLocalPlayer.localPlayer().alias!
        
        if GameKitHelper.sharedInstance._isServer {
            self.scene.start(GameScene.GameMode.Server)
        } else {
            self.scene.start(GameScene.GameMode.Client)
        }
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

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func matchStarted() {
        
    }
    
    func matchEnded() {
        scene.gameOver()
    }
    
    func match(match: GKMatch, didReceiveData: NSData, fromPlayer: GKPlayer) {
        if GameKitHelper.sharedInstance._isServer {
            scene.serverDelegate.receiveData(didReceiveData, fromPlayer: fromPlayer)
        } else {
            scene.clientDelegate.receiveData(didReceiveData, fromPlayer: fromPlayer)
        }
    }
}