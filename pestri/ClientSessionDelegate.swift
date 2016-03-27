import SpriteKit
import GameKit

class ClientSessionDelegate : NSObject {
    
    var scene : GameScene!
    var clientID : String? = nil
    var newestBroadcast : JSON? = nil
    
    // Special optimization for food
    var foodSet = Set<String>()
    
    init(scene : GameScene) {
        self.scene = scene
    }
    
    
    // NETWORK
    
    func send(json: JSON, dataMode: GKMatchSendDataMode) {
        if !GameKitHelper.sharedInstance._matchStarted || GameKitHelper.sharedInstance._match == nil {
            return
        }
        do {
            try GameKitHelper.sharedInstance._match?.sendData(json.rawData(), toPlayers: [GameKitHelper.sharedInstance._serverPlayer!], dataMode: dataMode)
        } catch let e as NSError {
            print(e)
        }

    }

    func requestSpawn() {
        let json : JSON = ["type": "SPAWN", "name": self.scene.playerName]
        send(json, dataMode: .Reliable)
    }
    
    func requestMove(position : CGPoint) {
        let json : JSON = ["type" : "MOVE", "x" : Double(position.x), "y": Double(position.y)]
        send(json, dataMode: .Unreliable)
    }
    
    func requestSplit() {
        let json : JSON = ["type" : "SPLIT"]
        send(json, dataMode: .Reliable)
    }
    
    func requestFloating() {
        let json : JSON = ["type" : "FLOATING"]
        send(json, dataMode: .Unreliable)
    }
    
    func updateScene() {
        if let json = newestBroadcast {
            
            // Special optimization for Food layer
            if json["foods"].count > 0 {
                var newids = Set<String>()
                for (_, subjson):(String, JSON) in json["foods"] {
                    let nm = subjson["name"].stringValue
                    newids.insert(nm)
                    if !foodSet.contains(nm) {
                        let fd = Food(foodColor: randomColor())
                        fd.name = nm
                        fd.position.x = CGFloat(subjson["x"].double!)
                        fd.position.y = CGFloat(subjson["y"].double!)
                        self.scene.foodLayer.addChild(fd)
                        self.foodSet.insert(nm)
                    }
                }
                for nd in self.scene.foodLayer.children {
                    if !newids.contains(nd.name!) {
                        nd.removeFromParent()
                        foodSet.remove(nd.name!)
                    }
                }
            }
            
            // Player layer synchronization
            updateLayer(scene.playerLayer, array: json["players"], handler: {(node : SKNode?, playerJSON) -> Void in
                var ballLayer : Player? = nil
                if let nd = node {
                    ballLayer = (nd as! Player)
                } else {
                    // New player
                    let player : Player = Player(playerName: playerJSON["displayName"].stringValue, parentNode: self.scene.playerLayer)
                    player.name = playerJSON["name"].stringValue
                    player.removeAllChildren()
                    
                    ballLayer = player
                }
                
                if let layer = ballLayer {
                    self.updateLayer(layer, array: playerJSON["balls"], handler: { (node : SKNode?, ballJSON) -> Void in
                        let p = CGPoint(x: CGFloat(ballJSON["x"].doubleValue),
                            y: CGFloat(ballJSON["y"].doubleValue))
                        let v = CGVector(dx: CGFloat(ballJSON["dx"].doubleValue),
                            dy: CGFloat(ballJSON["dy"].doubleValue))
                        let td = CGVector(dx: CGFloat(ballJSON["tdx"].doubleValue),
                            dy: CGFloat(ballJSON["tdy"].doubleValue))
                        if let nd = node { // Update ball
                            let ball = nd as! Ball
                            ball.targetDirection = td
                            ball.physicsBody!.velocity = v
                            //ball.position = p
                            
                            // Simple interpolation
                            let newv : CGVector = p - ball.position
                            let newvl = newv.length()
                            if newvl > ball.radius * 1.5 {
                                ball.position = p
                            } else {
                                ball.physicsBody!.velocity = v + newv.normalize() * (min(newvl, ball.radius) / ball.radius * ball.maxVelocity)
                            }
                            
                            let ms = CGFloat(ballJSON["mass"].doubleValue)
                            if ball.mass != ms {
                                ball.setNewMass(ms)
                                ball.drawBall()
                            }
                        } else { // New ball
                            let ball = Ball(ballName: ballJSON["ballName"].stringValue, ballColor: UIColor(hex: ballJSON["color"].intValue), ballMass: CGFloat(ballJSON["mass"].doubleValue), ballPosition: p)
                            ball.targetDirection = td
                            ball.name = ballJSON["name"].stringValue
                            ball.physicsBody!.velocity = v
                            layer.addChild(ball)
                        }
                    })
                }
            })
            
            self.updateLayer(self.scene.virusLayer, array: json["virus"], handler: { (node : SKNode?, json) -> Void in
                if let _ = node {
                    // Wont need any change
                } else {
                    let br = Virus()
                    br.name = json["name"].stringValue
                    br.position.x = CGFloat(json["x"].double!)
                    br.position.y = CGFloat(json["y"].double!)
                    self.scene.virusLayer.addChild(br)
                }
            })
            
            if let nm = clientID {
                if self.scene.currentPlayer == nil || self.scene.currentPlayer!.name != nm {
                    self.scene.currentPlayer = scene.playerLayer.childNodeWithName(nm) as! Player?   
                }
            }
            
            newestBroadcast = nil
        }
    }
    
    func updateLayer(layer : SKNode, array : JSON, handler: (SKNode?, JSON) -> Void) {
        var newids = Set<String>()
        for (_, subjson):(String, JSON) in array {
            newids.insert(subjson["name"].stringValue)
        }
        // Remove dead node
        for var i = layer.children.count - 1; i >= 0; i -= 1 {
            let nd : SKNode = layer.children[i]
            if !newids.contains(nd.name!) {
                nd.removeFromParent()
                nd.removeAllChildren()
            }
        }
        
        // Update rest nodes and insert nodes
        for (_, subjson):(String, JSON) in array {
            let nm = subjson["name"].stringValue
            let nd = layer.childNodeWithName(nm)
            handler(nd, subjson)
        }
    }
    
    func receiveData(data: NSData, fromPlayer player: GKPlayer) {
        let json = JSON(data: data)
        // print("Got something in client: ", json)
        if json["type"].stringValue == "SPAWN" {
            print("Got feedback: ", json["ID"].stringValue)
            if json["ID"].stringValue != "" {
                self.clientID = json["ID"].stringValue
            }
        }
        if json["type"].stringValue == "BROADCAST" {
            newestBroadcast = json
        }
    }
}
