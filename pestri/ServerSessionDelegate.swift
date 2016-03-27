import SpriteKit
import GameKit

class ServerSessionDelegate : NSObject {
    
    var scene : GameScene!
    
    var userDict : Dictionary<String, String> = Dictionary<String, String>()
    
    // A hack to improve performance
    var foodMask : Int = 0
    
    init(scene : GameScene) {
        self.scene = scene
    }
    
    func broadcast() {
        if !GameKitHelper.sharedInstance._matchStarted || GameKitHelper.sharedInstance._match == nil {
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            var json : JSON = ["type": "BROADCAST"]
            
            // Food & a hack to improve performance
            if self.foodMask == 0 {
                var foodArray : [JSON] = []
                for f in self.scene.foodLayer.children as! [Food] {
                    foodArray.append(f.toJSON())
                }
                json["foods"] = JSON(foodArray)
            }
            self.foodMask = (self.foodMask + 1) % 4
            
            // Players & Balls
            var playerArray : [JSON] = []
            for f in self.scene.playerLayer.children as! [Player] {
                playerArray.append(f.toJSON())
            }
            json["players"] = JSON(playerArray)
            
            // Virus
            var virusArray : [JSON] = []
            for f in self.scene.virusLayer.children as! [Virus] {
                virusArray.append(f.toJSON())
            }
            json["virus"] = JSON(virusArray)
            
            do {
                try GameKitHelper.sharedInstance._match?.sendDataToAllPlayers(json.rawData(), withDataMode: .Unreliable)
            } catch let e as NSError {
                print(e)
            }
        }
    }
    
    func receiveData(data: NSData, fromPlayer player: GKPlayer) {
        let json = JSON(data: data)
        if json["type"].stringValue == "SPAWN" {
            dispatch_async(dispatch_get_main_queue(), {
                let p = Player(playerName: json["name"].stringValue, parentNode: self.scene.playerLayer, initPosition: randomPosition())
                let response : JSON = ["type": "SPAWN", "ID": p.name!]
                self.userDict[player.playerID!] = p.name!
                do {
                    print("Sending spawn info to ", player.playerID!, "info: ", response["ID"].stringValue)
                    try GameKitHelper.sharedInstance._match?.sendData(response.rawData(), toPlayers: [player], dataMode: .Reliable)
                } catch let e as NSError {
                    print("Something wrong when sending SPAWN info back", e)
                }
            })
        }
        if json["type"].stringValue == "MOVE" {
            let p : CGPoint = CGPoint(x: json["x"].doubleValue, y: json["y"].doubleValue)
            if let nm = userDict[player.playerID!] {
                if let nd = scene.playerLayer.childNodeWithName(nm) {
                    let player = nd as! Player
                    dispatch_async(dispatch_get_main_queue(), {
                        player.move(p)
                    })
                }
            }
        }
        if json["type"].stringValue == "FLOATING" {
            if let nm = userDict[player.playerID!] {
                if let nd = scene.playerLayer.childNodeWithName(nm) {
                    let player = nd as! Player
                    dispatch_async(dispatch_get_main_queue(), {
                        player.floating()
                    })
                }
            }
        }
        if json["type"].stringValue == "SPLIT" {
            if let nm = userDict[player.playerID!] {
                if let nd = scene.playerLayer.childNodeWithName(nm) {
                    let player = nd as! Player
                    dispatch_async(dispatch_get_main_queue(), {
                        player.split()
                    })
                }
            }
        }
    }
}
