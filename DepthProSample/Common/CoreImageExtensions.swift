import CoreImage
import ImageIO
import UniformTypeIdentifiers

extension CIImage {
    /// Returns a resized image.
    func resized(to size: CGSize) -> CIImage {
        let outputScaleX = size.width / extent.width
        let outputScaleY = size.height / extent.height
        var outputImage = self.transformed(by: CGAffineTransform(scaleX: outputScaleX, y: outputScaleY))
        outputImage = outputImage.transformed(
            by: CGAffineTransform(translationX: -outputImage.extent.origin.x, y: -outputImage.extent.origin.y)
        )
        return outputImage
    }
}

extension CGImage {
    func resized(to size: CGSize) -> CGImage? {
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: destWidth,
            height: destHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        
        context.scaleBy(x: 1.0, y: 1.0)
        context.draw(self, in: CGRect(x: 0, y: 0, width: destWidth, height: destHeight))
        
        return context.makeImage()
    }
}

extension CIContext {
    /// Renders an image to a new pixel buffer.
    func render(_ image: CIImage, pixelFormat: OSType) -> CVPixelBuffer? {
        var output: CVPixelBuffer!
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.extent.width),
            Int(image.extent.height),
            pixelFormat,
            nil,
            &output
        )
        guard status == kCVReturnSuccess else {
            return nil
        }
        render(image, to: output)
        return output
    }

    /// Writes the image as a PNG.
    func writePNG(_ image: CIImage, to url: URL) {
        let outputCGImage = createCGImage(image, from: image.extent)!
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            fatalError("Failed to create an image destination.")
        }
        CGImageDestinationAddImage(destination, outputCGImage, nil)
        CGImageDestinationFinalize(destination)
    }
}
