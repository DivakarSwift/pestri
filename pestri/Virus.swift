import SpriteKit

class Virus : SKSpriteNode {
    var radius = GlobalConstants.VirusRadius
    
    init() {
        super.init(texture: SKTexture(imageNamed: "virus"),
            color: SKColor.whiteColor(),
            size: CGSize(width: 2 * radius, height: 2 * radius))
        self.name   = "virus-" + NSUUID().UUIDString
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.dynamic = false
        self.physicsBody?.categoryBitMask = GlobalConstants.Category.virus
        self.physicsBody?.collisionBitMask = GlobalConstants.Category.wall | GlobalConstants.Category.virus
        self.physicsBody?.contactTestBitMask = GlobalConstants.Category.ball
        self.zPosition = GlobalConstants.ZPosition.virus
        
        self.position = randomPosition()
        
        // Let barrier spin
        let spin = SKAction.rotateByAngle(CGFloat(M_PI*2), duration: 10)
        self.runAction(SKAction.repeatActionForever(spin))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toJSON() -> JSON {
        let json : JSON = ["name": self.name!, "x": round(Double(self.position.x)), "y": round(Double(self.position.y))]
        return json
    }
}