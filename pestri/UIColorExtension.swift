import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
    
    func darkerColor() -> UIColor {
        let rgb = CGColorGetComponents(self.CGColor)
        let r = CGFloat(255.0 * rgb[0])
        let g = CGFloat(255.0 * rgb[1])
        let b = CGFloat(255.0 * rgb[2])
        return self.dynamicType.init(red: max(r * 0.8 / 255, 0.0), green:max(g * 0.8 / 255, 0.0), blue:max(b * 0.8 / 255, 0.0), alpha:255)
    }
    
    func toHexString() -> NSString {
        let rgb = CGColorGetComponents(self.CGColor)
        let r = Float(255.0 * rgb[0])
        let g = Float(255.0 * rgb[1])
        let b = Float(255.0 * rgb[2])
    
        return NSString.init(format: "%02lX%02lX%02lX", lroundf(r), lroundf(g), lroundf(b))
    }
}