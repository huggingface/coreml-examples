import CoreML
import CoreImage
import CoreImage.CIFilterBuiltins

enum PostProcessorError : Error {
    case missingModelMetadata
    case colorConversionError
}

class DETRPostProcessor {
    /// Number of raw classes, including empty ones with no labels
    let numClasses: Int

    /// Map from semantic id to class label
    let ids2Labels: [Int : String]

    init(model: MLModel) throws {
        struct ClassList: Codable {
            var labels: [String]
        }

        guard let userFields = model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as? [String : String],
              let params = userFields["com.apple.coreml.model.preview.params"] else {
            throw PostProcessorError.missingModelMetadata
        }
        guard let jsonData = params.data(using: .utf8),
              let classList = try? JSONDecoder().decode(ClassList.self, from: jsonData) else {
            throw PostProcessorError.missingModelMetadata
        }
        let rawLabels = classList.labels

        // Filter out empty categories whose label is "--"
        let ids2Labels = Dictionary(uniqueKeysWithValues: rawLabels.enumerated().filter { $1 != "--" })

        self.numClasses = rawLabels.count
        self.ids2Labels = ids2Labels
    }

    /// Creates a new CIImage from a raw semantic predictions returned by the model
    func semanticImage(semanticPredictions: MLShapedArray<Int32>) throws -> CIImage {
        guard let image = try SemanticMapToImage.shared?.mapToImage(semanticMap: semanticPredictions, numClasses: numClasses) else {
            throw PostProcessorError.colorConversionError
        }
        return image
    }
}
