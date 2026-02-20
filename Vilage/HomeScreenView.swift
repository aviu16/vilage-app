import SwiftUI
import AVKit

struct HomescreenView: View {
    @State private var navigateToImageUpload = false

    var body: some View {
        NavigationView {
            ZStack {
                VideoPlayerView()
                    .edgesIgnoringSafeArea(.all)
                    .overlay(FullScreenOverlayView(), alignment: .center)

                VStack {
                    Spacer()
                    StaticTitleView()
                    Spacer()
                    StartButtonView(navigateToImageUpload: $navigateToImageUpload)
                        .padding(.bottom, 50) // Adjust this value to move the button higher
                }
            }
        }
    }
}

struct FullScreenOverlayView: View {
    var body: some View {
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
    }
}

struct StaticTitleView: View {
    var body: some View {
        Text("Your App Title")
            .font(.system(size: 70, weight: .bold))
            .foregroundColor(.white)
    }
}

struct StartButtonView: View {
    @Binding var navigateToImageUpload: Bool

    var body: some View {
        NavigationLink(destination: ImageUploadView(), isActive: $navigateToImageUpload) {
            Text("Start")
                .foregroundColor(Color.black)
                .font(.headline)
                .frame(width: 200, height: 50)
                .background(Color.white)
                .cornerRadius(25)
                .shadow(radius: 5)
        }
    }
}

struct VideoPlayerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class PlayerUIView: UIView {
        private var player: AVPlayer?
        private let playerLayer = AVPlayerLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            guard let path = Bundle.main.path(forResource: "00005", ofType:"mp4") else {
                return
            }
            player = AVPlayer(url: URL(fileURLWithPath: path))
            player?.isMuted = true
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
                self?.player?.seek(to: CMTime.zero)
                self?.player?.play()
            }
            
            player?.play()
            
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomescreenView()
    }
}
