import CoreML
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

class SemanticMapToImage {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState

    public static let shared: SemanticMapToImage? = SemanticMapToImage()

    enum MetalConversionError : Error {
        case commandBufferError
        case encoderError
        case coreImageError
    }

    public init?() {
        guard let theMetalDevice = MTLCreateSystemDefaultDevice() else { return nil }
        device = theMetalDevice

        guard let cmdQueue = theMetalDevice.makeCommandQueue() else { return nil }
        commandQueue = cmdQueue

        guard let library = device.makeDefaultLibrary() else {
            return nil
        }

        guard let makeContiguousKernel = library.makeFunction(name: "SemanticMapToColor") else {
            return nil
        }

        guard let pipelineState = try? device.makeComputePipelineState(function: makeContiguousKernel) else {
            return nil
        }
        self.pipelineState = pipelineState
    }

    public func mapToImage(semanticMap: MLShapedArray<Int32>, numClasses: Int) throws -> CIImage {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw MetalConversionError.commandBufferError
        }
        guard let outputTexture = encodeComputePipeline(commandBuffer: commandBuffer, semanticMap: semanticMap, numClasses: numClasses) else {
            throw MetalConversionError.encoderError
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard let image = CIImage(mtlTexture: outputTexture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]) else {
            throw MetalConversionError.coreImageError
        }
        return image
            .transformed(by: CGAffineTransform(scaleX: 1, y: -1))
            .transformed(by: CGAffineTransform(translationX: 0, y: image.extent.height))
    }

    func encodeComputePipeline(commandBuffer: MTLCommandBuffer, semanticMap: MLShapedArray<Int32>, numClasses: Int) -> MTLTexture? {
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        commandEncoder.setComputePipelineState(pipelineState)

        let (width, height) = (semanticMap.shape[0], semanticMap.shape[1])
        guard let outputTexture = makeTexture(width: width, height: height, pixelFormat: .bgra8Unorm) else { return nil }

        commandEncoder.setTexture(sourceTexture(semanticMap), index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)

        // FIXME: hardcoded for now
        var classCount = numClasses
        commandEncoder.setBytes(&classCount, length: MemoryLayout<Int32>.size, index: 0)

        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadsPerGrid = MTLSize(width: outputTexture.width,
                                     height: outputTexture.height,
                                     depth: 1)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()

        return outputTexture
    }

    func sourceTexture(_ semanticMap: MLShapedArray<Int32>) -> MTLTexture? {
        let (width, height) = (semanticMap.shape[0], semanticMap.shape[1])
        let texture = makeTexture(width: width, height: height)
        let region = MTLRegionMake2D(0, 0, width, height)
        let array = MLMultiArray(semanticMap)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: array.dataPointer, bytesPerRow: width * MemoryLayout<Int32>.stride)
        return texture
    }

    func makeTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .r32Uint) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: textureDescriptor)
    }
}
