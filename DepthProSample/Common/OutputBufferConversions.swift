import CoreImage

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
