import SpriteKit

class Food : SKSpriteNode {
    
    var radius = GlobalConstants.FoodRadius
    
    static var counter : Int = 0
    
    init(foodColor color: UIColor){
        super.init(texture: SKTexture(imageNamed: "circle"), color: color, size: CGSize(width: radius * 2, height: radius * 2))
        self.colorBlendFactor = 1;
        self.name   = "food-" + NSUUID().UUIDString
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.dynamic = false
        self.physicsBody?.categoryBitMask = GlobalConstants.Category.food
        self.physicsBody?.collisionBitMask = GlobalConstants.Category.wall
        self.physicsBody?.contactTestBitMask = GlobalConstants.Category.ball
        self.zPosition = GlobalConstants.ZPosition.food
        
        self.position = randomPosition()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toJSON() -> JSON {
        let json : JSON = ["name": self.name!, "color": colorToHex(self.color),
            "x": Double(self.position.x), "y": Double(self.position.y)]
        return json
    }
}