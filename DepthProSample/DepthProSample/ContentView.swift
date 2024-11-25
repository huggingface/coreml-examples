import SwiftUI
import CoreML
import Vision

let targetSize = CGSize(width: 1536, height: 1536)
let context = CIContext()

struct ContentView: View {
    @State private var pixelBuffer: CVPixelBuffer?
    @State private var originalSize: CGSize?
    @State private var selectedImage: Image?
    @State private var processedImage: Image?
    @State private var isImagePickerPresented = false
    
    var body: some View {
        VStack {
            selectedImage?
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(10)
            
            Button("Select Image") {
                isImagePickerPresented = true
            }
            .fileImporter(isPresented: $isImagePickerPresented, allowedContentTypes: [.png, .jpeg], allowsMultipleSelection: false, onCompletion: {
                results in switch results {
                    case .success(let fileurls):
                        if fileurls.count > 0 {
                            loadImage(inputURL: fileurls.first!)
                        }
                        
                    case .failure(let error):
                        print(error)
                }
            })
            
            Button("Process Image") {
                do {
                    try processImage();
                }  catch {
                    print(error)
                }
            }
            .disabled(selectedImage == nil)
//            
            processedImage?
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(10)
//            
//            if processedImage != nil {
//                Button("Save Image") {
//                    // Save implementation
//                }
//            }
        }
        .padding()
    }
    
    func loadImage(inputURL: URL) {
        guard let inputImage = CIImage(contentsOf: inputURL) else {
            print("Failed to load image.")
            return
        }
        
        selectedImage = Image(decorative: context.createCGImage(inputImage, from: inputImage.extent)!, scale: 1.0, orientation: .up)
        
        self.originalSize = inputImage.extent.size

        let resizedImage = inputImage.resized(to: targetSize)

        guard let pixelBuffer = context.render(resizedImage, pixelFormat: kCVPixelFormatType_32ARGB)
        else {
            print("Failed to create a pixel buffer.")
            return
        }
        
        self.pixelBuffer = pixelBuffer
    }
    
    func processImage() throws{
        guard let image = selectedImage else { return }
        guard let pb = pixelBuffer else { return }
        
        let model = try DepthProNIDPrunedQuantized()
        
        let result = try model.prediction(pixel_values: pb)
        guard
          let outputPixelBuffer = result.featureValue(for: "normalized_inverse_depth")?.imageBufferValue
        else {
          print("The model did not return a 'normalized_inverse_depth' feature with an image.")
            return
        }
        
        let castedBuffer = castPixelBuffer(outputPixelBuffer)!
        let normalizedBuffer = normalizePixelBuffer(castedBuffer)!

        var outputImage = CIImage(cvPixelBuffer: normalizedBuffer)
        outputImage = outputImage.resized(
            to: CGSize(width: originalSize!.width, height: originalSize!.height))
        processedImage = Image(decorative: context.createCGImage(outputImage, from: outputImage.extent)!, scale: 1.0, orientation: .up)
    }
    
    func saveImage() {
//        guard let image = processedImage else { return }
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct ImagePicker: View {
    @Binding var selectedImage: Image?
    @State private var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            List {
                Button("Photo Library") {
                    selectImageFromLibrary()
                }
                Button("Camera") {
                    selectImageFromCamera()
                }
            }
        }
    }
    
    private func selectImageFromLibrary() {
        // Library image selection logic
        dismiss()
    }
    
    private func selectImageFromCamera() {
        // Camera image capture logic
        dismiss()
    }
}
