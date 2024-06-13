import AVFoundation
import SwiftUI

struct SegmentationView: View {
    @Binding var image: Image?

    var body: some View {
        if let image = image {
            image.resizable().aspectRatio(contentMode: .fill)
        }
    }
}

#Preview {
    SegmentationView(image: .constant(Image(systemName: "circle.rectangle.filled.pattern.diagonalline")))
}
