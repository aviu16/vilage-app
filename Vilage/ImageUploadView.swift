import SwiftUI

struct ImageUploadView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var navigateToProcessing = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // Full-screen black background

                VStack {
                    ZStack {
                        Rectangle()
                            .fill(selectedImage == nil ? Color.white : Color.clear)
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                Group {
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.black)
                                    }
                                }
                            )
                        .cornerRadius(10)
                    }
                    .padding()

                    HStack {
                        Button("Upload Image") {
                            showingImagePicker = true
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Convert to Video") {
                            navigateToProcessing = selectedImage != nil
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selectedImage == nil || isUploading)
                    }
                    .padding(.bottom)

                    NavigationLink(destination: VideoProcessingView(selectedImage: selectedImage), isActive: $navigateToProcessing) {
                        EmptyView()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImageUploadView_Previews: PreviewProvider {
    static var previews: some View {
        ImageUploadView()
    }
}
