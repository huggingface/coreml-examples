import AVFoundation
import SwiftUI

struct DepthView: View {
    @Binding var image: Image?

    var body: some View {
        if let image = image {
            image.resizable().aspectRatio(contentMode: .fill)
        }
    }
}

#Preview {
    DepthView(image: .constant(Image(systemName: "circle.rectangle.filled.pattern.diagonalline")))
}
