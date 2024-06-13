import SwiftUI

struct CameraView: View {
    @StateObject private var model = DataModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    ViewfinderView(session: model.camera.captureSession, prediction: $model.prediction)
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
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
