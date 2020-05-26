import UIKit
import CoreImage

public extension UIImage {
    
    func resized(to target: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
    
    func combined(with image: UIImage, corner: UIRectCorner) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = true
                
        let origin: CGPoint
        switch corner {
        case .bottomRight:
            origin = CGPoint(x: size.width - image.size.width, y: size.height - image.size.height)
        default:
            fatalError()
        }
        
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        return renderer.image { _ in
            draw(at: .zero)
            image.draw(at: origin)
        }
    }
}

public extension UIImage {
    
    struct CIFilterName {
        static let noir = "CIPhotoEffectNoir"
        static let gaussianBlur = "CIGaussianBlur"
        static let code128BarcodeGenerator = "CICode128BarcodeGenerator"
    }
    
    func noir() -> UIImage {
        let filter = CIFilter(name: CIFilterName.noir)!
        let ciInput = ciImage ?? CIImage(cgImage: cgImage!)
        filter.setValue(ciInput, forKey: kCIInputImageKey)
        let ciOutput = filter.outputImage!
        let cgImage = CIContext().createCGImage(ciOutput, from: ciOutput.extent)!
        return UIImage(cgImage: cgImage)
    }
    
    func gaussianBlur(radius: CGFloat = 40, cropExtent: Bool = true) -> UIImage {
        let filter = CIFilter(name: CIFilterName.gaussianBlur)!
        let ciInput = ciImage ?? CIImage(cgImage: cgImage!)
        filter.setValue(ciInput, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        var ciImage = filter.outputImage!
        
        if cropExtent {
            var rect = ciImage.extent
            rect.origin.x = -1 * rect.origin.x
            rect.origin.y = -1 * rect.origin.y
            rect.size.width -= 4 * rect.origin.x
            rect.size.height -= 4 * rect.origin.y
            ciImage = ciImage.cropped(to: rect)
        }
        
        let cgOutput = CIContext().createCGImage(ciImage, from: ciImage.extent)!
        return UIImage(cgImage: cgOutput)
    }
}

public typealias ImageFilter = (UIImage) -> (UIImage)

public enum ImageFilters {
    public static var none: ImageFilter = { $0 }
    public static var gaussianBlur: ImageFilter = { $0.gaussianBlur() }
    public static var noir: ImageFilter = { $0.noir() }
}
