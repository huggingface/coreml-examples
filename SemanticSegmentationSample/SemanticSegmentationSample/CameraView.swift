import SwiftUI

struct CameraView: View {
    @StateObject private var model = DataModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    ViewfinderView(session: model.camera.captureSession)
                        .frame(width: geometry.size.width, height: geometry.size.height / 2).clipped()
                    SegmentationView(image: $model.segmentationImage).background(.black)
                        .frame(width: geometry.size.width, height: geometry.size.height / 2).clipped()
                }
            }
            .task {
                await model.camera.start()
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .statusBar(hidden: true)
            .ignoresSafeArea()
        }
    }
}
