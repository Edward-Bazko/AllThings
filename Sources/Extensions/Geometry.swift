import UIKit

extension CGRect {
    func scaled(factor: CGFloat) -> CGRect {
        return CGRect(x: origin.x * factor,
                      y: origin.y * factor,
                      width: size.width * factor,
                      height: size.height * factor)
    }
}

extension CGPoint {
    func scaled(factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }
}

extension CGSize {
    func scaled(factor: CGFloat) -> CGSize {
        return CGSize(width: width * factor, height: height * factor)
    }
    
    func scaleToFit(_ another: CGSize) -> CGFloat {
        return min(another.width / width,
                   another.height / height)
    }
    
    func scaleToFill(_ another: CGSize) -> CGFloat {
        return max(another.width / width,
                   another.height / height)
    }
    
    func roundedDown() -> CGSize {
        return CGSize(width: width.rounded(.down), height: height.rounded(.down))
    }
    
    enum AspectRatioMode {
        case scaleToFill
        case aspectFit
        case aspectFill
    }
    
    enum ScalingMode {
        case disableUpscaling
        case enableUpscaling
    }
    
    func resized(to target: CGSize,
                 ratio: AspectRatioMode,
                 scaling: ScalingMode = .disableUpscaling) -> CGSize {
        
        var scale: CGFloat
        switch ratio {
        case .scaleToFill:
            scale = 0
        case .aspectFit:
            scale = scaleToFit(target)
        case .aspectFill:
            scale = scaleToFill(target)
        }
        
        if scale > 1, scaling == .disableUpscaling {
            return self
        }
        else if scale == 0 {
            return target
        }
        else {
            return scaled(factor: scale)
        }
    }
}

// MARK: - Hashables

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
