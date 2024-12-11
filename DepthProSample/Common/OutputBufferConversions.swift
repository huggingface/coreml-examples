import CoreImage
import CoreML

func castPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

  guard pixelFormat == kCVPixelFormatType_OneComponent16Half else {
    print("Unsupported pixel format. This function requires a 16-bit half-precision pixel buffer.")
    return nil
  }

  var normalizedPixelBuffer: CVPixelBuffer?
  let attributes: [CFString: Any] = [
    kCVPixelBufferWidthKey: width,
    kCVPixelBufferHeightKey: height,
    kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent32Float,
    kCVPixelBufferIOSurfacePropertiesKey: [:],
  ]

  CVPixelBufferCreate(
    kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent32Float,
    attributes as CFDictionary, &normalizedPixelBuffer)

  guard let outputBuffer = normalizedPixelBuffer else {
    print("Failed to create output pixel buffer.")
    return nil
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
  CVPixelBufferLockBaseAddress(outputBuffer, [])
  defer {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    CVPixelBufferUnlockBaseAddress(outputBuffer, [])
  }

  guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
    let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer)
  else {
    print("Failed to get the base address of the pixel buffer.")
    return nil
  }

  let inputPointer = inputBaseAddress.bindMemory(to: UInt16.self, capacity: width * height)
  let outputPointer = outputBaseAddress.bindMemory(to: Float.self, capacity: width * height)

  let pixelCount = width * height

  for i in 0..<pixelCount {
    let halfValue = inputPointer[i]
    let floatValue = Float(halfToFloat(halfValue))
    outputPointer[i] = floatValue
  }

  return outputBuffer
}

func normalizePixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

  guard pixelFormat == kCVPixelFormatType_OneComponent32Float else {
    print("Unsupported pixel format. This function requires a 32-bit half-precision pixel buffer.")
    return nil
  }

  var normalizedPixelBuffer: CVPixelBuffer?
  let attributes: [CFString: Any] = [
    kCVPixelBufferWidthKey: width,
    kCVPixelBufferHeightKey: height,
    kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent32Float,
    kCVPixelBufferIOSurfacePropertiesKey: [:],
  ]

  CVPixelBufferCreate(
    kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent32Float,
    attributes as CFDictionary, &normalizedPixelBuffer)

  guard let outputBuffer = normalizedPixelBuffer else {
    print("Failed to create output pixel buffer.")
    return nil
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
  CVPixelBufferLockBaseAddress(outputBuffer, [])
  defer {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    CVPixelBufferUnlockBaseAddress(outputBuffer, [])
  }

  guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
    let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer)
  else {
    print("Failed to get the base address of the pixel buffer.")
    return nil
  }

  let inputPointer = inputBaseAddress.bindMemory(to: Float.self, capacity: width * height)
  let outputPointer = outputBaseAddress.bindMemory(to: Float.self, capacity: width * height)

  let pixelCount = width * height

  for i in 0..<pixelCount {
    outputPointer[i] = inputPointer[i] / 255.0
  }

  return outputBuffer
}

func halfToFloat(_ half: UInt16) -> Float {
  let sign = (half & 0x8000) >> 15
  let exponent = (half & 0x7C00) >> 10
  let fraction = half & 0x03FF

  if exponent == 0 {
    // Subnormal number or zero
    if fraction == 0 {
      return sign == 0 ? 0.0 : -0.0
    } else {
      let floatValue = Float(fraction) / 1024.0
      return sign == 0 ? floatValue : -floatValue
    }
  } else if exponent == 0x1F {
    // Inf or NaN
    if fraction == 0 {
      return sign == 0 ? Float.infinity : -Float.infinity
    } else {
      return Float.nan
    }
  }

  let floatExponent = Float(Int(exponent) - 15)
  let floatValue = (1.0 + Float(fraction) / 1024.0) * pow(2.0, floatExponent)

  return sign == 0 ? floatValue : -floatValue
}

// Define the colors as an array of tuples (R, G, B)
let baseColors: [(UInt8, UInt8, UInt8)] = [
    (255, 255, 255),  // 0.0-0.1m: White
    (255, 255, 128),  // 0.1-0.2m: Bright yellow
    (255, 255, 0),    // 0.2-0.3m: Yellow
    (255, 230, 0),    // 0.3-0.4m: Golden yellow
    (255, 200, 0),    // 0.4-0.5m: Orange yellow
    (255, 170, 0),    // 0.5-0.6m: Light orange
    (255, 140, 0),    // 0.6-0.7m: Orange
    (255, 110, 0),    // 0.7-0.8m: Dark orange
    (255, 80, 0),     // 0.8-0.9m: Red orange
    (255, 50, 0),     // 0.9-1.0m: Bright red
    (255, 0, 0),      // 1.0-1.1m: Pure red
    (230, 0, 0),      // 1.1-1.2m: Medium red
    (200, 0, 0),      // 1.2-1.3m: Dark red
    (170, 0, 0),      // 1.3-1.4m: Darker red
    (140, 0, 0),      // 1.4-1.5m: Very dark red
    (128, 0, 128),    // 1.5-1.6m: Purple
    (110, 0, 110),    // 1.6-1.7m: Dark purple
    (90, 0, 90),      // 1.7-1.8m: Darker purple
    (70, 0, 70),      // 1.8-1.9m: Very dark purple
    (50, 0, 50),      // 1.9-2.0m: Almost black purple
    (0, 128, 255),    // 2.0-2.1m: Bright blue
    (0, 100, 230),    // 2.1-2.2m: Medium blue
    (0, 80, 200),     // 2.2-2.3m: Dark blue
    (0, 60, 170),     // 2.3-2.4m: Darker blue
    (0, 40, 140),     // 2.4-2.5m: Very dark blue
    (0, 100, 0),      // 2.5-2.6m: Dark green
    (0, 80, 0),       // 2.6-2.7m: Darker green
    (0, 60, 0),       // 2.7-2.8m: Very dark green
    (0, 40, 0),       // 2.8-2.9m: Almost black green
    (20, 20, 20),     // 2.9-3.0m: Near black
    (15, 15, 15),     // 3.0-3.1m: Darker near black
    (10, 10, 10),     // 3.1-3.2m: Very dark near black
    (5, 5, 5),        // 3.2-3.3m: Almost black
    (2, 2, 2),        // 3.3-3.4m: Almost Pure black
    (0, 0, 0),        // 3.4-3.5m: Pure black
]

func arrayToColoredMap(_ elevationArray: MLMultiArray) -> CGImage? {
    let height = elevationArray.shape[2].intValue
    let width = elevationArray.shape[3].intValue
    
    // Create a buffer to hold the resulting color image
    var colorMap: [UInt8] = [UInt8](repeating: 0, count: height * width * 3)  // RGB values for each pixel
    
    // Scale the elevation values by 10 (as in Python code)
    for row in 0..<height {
        for col in 0..<width {
            let index = row * width + col
            // Get the elevation value at this position
            let elevationValue = elevationArray[[0, 0, NSNumber(value: row), NSNumber(value: col)]].doubleValue
            let scaledElevation = Int(elevationValue * 10)
            
            // Clip the value to ensure it's within the valid range of base colors
            let clippedElevation = min(max(scaledElevation, 0), baseColors.count - 1)
            
            // Get the corresponding color from the base colors array
            let (r, g, b) = baseColors[clippedElevation]
            
            // Set the color values in the colorMap buffer (RGB format)
            colorMap[index * 3] = r
            colorMap[index * 3 + 1] = g
            colorMap[index * 3 + 2] = b
        }
    }
    
    let colorData = Data(colorMap)
    let providerRef = CGDataProvider(data: colorData as CFData)
    let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 24,
        bytesPerRow: width * 3,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: providerRef!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
    
    return cgImage
}
