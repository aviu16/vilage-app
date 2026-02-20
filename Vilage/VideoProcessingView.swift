import SwiftUI
import AVKit
import Photos
import Supabase

struct VideoProcessingView: View {
    var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var videoURL: URL?
    @State private var showVideoPlayer = false
    @State private var showingShareSheet = false
    @State private var predictionId: String?
    
    let supabaseClient = SupabaseClient(supabaseURL: "https://cgqkgilsmokmulkynkpw.supabase.co", supabaseKey: "YOUR_SUPABASE_ANON_KEY") // Replace with your actual Supabase URL and Key
    
    var body: some View {
                ZStack {
                    if let videoURL = videoURL, showVideoPlayer {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .edgesIgnoringSafeArea(.all)
                            .onAppear {
                                print("Displaying video from URL: \(videoURL)")
                            }
                    } else if isProcessing {
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                    } else {
                        Text("Waiting for Image...")
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Button("Download") {
                                downloadVideo()
                            }
                            .buttonStyle(DownloadShareButtonStyle())
                            
                            Button("Share") {
                                showingShareSheet = true
                            }
                            .buttonStyle(DownloadShareButtonStyle())
                        }
                        .padding()
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let videoURL = videoURL {
                        ActivityViewController(videoURL: videoURL)
                    }
                }
                .onAppear {
                    isProcessing = true
                    if let selectedImage = selectedImage {
                        uploadImage(selectedImage)
                    }
                }
            }

    
    
    private func convertImageToVideo(imageURL: URL) {
            let url = URL(string: "https://api.replicate.com/v1/predictions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Token YOUR_REPLICATE_API_TOKEN", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "version": "3f0457e4619daac51203dedb472816fd4af51f3149fa7a9e0b5ffcf1b8172438",
                "input": [
                    "input_image": imageURL.absoluteString,
                    "video_length": "14_frames_with_svd",
                    "sizing_strategy": "maintain_aspect_ratio",
                    "frames_per_second": 6,
                    "motion_bucket_id": 127,
                    "cond_aug": 0.02,
                    "decoding_t": 14
                ]
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to serialize JSON")
                return
            }
            
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("API Request Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Response JSON: \(jsonResponse)")
                        if let outputURL = jsonResponse["output"] as? String {
                            DispatchQueue.main.async {
                                self.videoURL = URL(string: outputURL)
                                self.showVideoPlayer = true
                            }
                        } else if let predictionId = jsonResponse["id"] as? String {
                            self.predictionId = predictionId
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.pollVideoStatus()
                            }
                        } else {
                            print("No output URL or prediction ID in response")
                        }
                    } else {
                        print("Failed to parse JSON or data is nil.")
                    }
                }
            }.resume()
        }
        
    private func pollVideoStatus() {
            guard let predictionId = predictionId else {
                print("No prediction ID for polling")
                return
            }

            let statusURL = URL(string: "https://api.replicate.com/v1/predictions/\(predictionId)")!
            var request = URLRequest(url: statusURL)
            request.httpMethod = "GET"
            request.addValue("Token YOUR_REPLICATE_API_TOKEN", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error checking video status: \(error.localizedDescription)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = jsonResponse["status"] as? String {
                        DispatchQueue.main.async {
                            if status == "succeeded" {
                                if let outputURL = jsonResponse["output"] as? String {
                                    print("Fetched video URL: \(outputURL)")
                                    self.videoURL = URL(string: outputURL)
                                    self.showVideoPlayer = true
                                } else {
                                    print("No output URL in the completed response")
                                }
                            } else if status == "failed" {
                                print("Video processing failed.")
                            } else {
                                print("Status is not completed: \(status), retrying polling")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    self.pollVideoStatus()
                                }
                            }
                        }
                    } else {
                        print("Invalid response or unable to parse JSON in polling")
                    }
                } else {
                    print("Failed polling request: \(response.debugDescription)")
                }
            }.resume()
        }

        
        private func uploadImage(_ image: UIImage) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert image to JPEG data.")
                return
            }
            
            let fileName = "images/\(UUID().uuidString).jpg"
            Task {
                do {
                    try await supabaseClient.storage.from("VilageImages").upload(path: fileName, file: imageData)
                    print("Image successfully uploaded.")
                    
                    // Constructing public URL for the uploaded image
                    let publicURL = URL(string: "https://cgqkgilsmokmulkynkpw.supabase.co/storage/v1/object/public/VilageImages/\(fileName)")
                    if let publicURL = publicURL {
                        self.convertImageToVideo(imageURL: publicURL)
                    } else {
                        print("Failed to construct public URL for the uploaded image.")
                    }
                } catch {
                    print("Failed to upload image: \(error.localizedDescription)")
                }
            }
        }
        
    
    
    private func downloadVideo() {
            guard let videoURL = videoURL else {
                print("No video URL available")
                return
            }
            
            let path = videoURL.path
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: path))
            }) { saved, error in
                DispatchQueue.main.async {
                    if saved {
                        print("Your video was successfully saved")
                    } else {
                        print("An error occurred while saving the video: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
        
        struct DownloadShareButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1)
            }
        }
        
        struct ActivityViewController: UIViewControllerRepresentable {
            var videoURL: URL
            var applicationActivities: [UIActivity]?
            var onCompleted: ((Bool, UIActivity.ActivityType?) -> Void)?

            func makeUIViewController(context: Context) -> UIActivityViewController {
                let controller = UIActivityViewController(activityItems: [videoURL], applicationActivities: applicationActivities)
                controller.completionWithItemsHandler = { activity, completed, items, error in
                    self.onCompleted?(completed, activity)
                }
                return controller
            }

            func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
        }

        
        struct VideoProcessingView_Previews: PreviewProvider {
            static var previews: some View {
                VideoProcessingView(selectedImage: UIImage(named: "sampleImage"))
            }
        }
    }
