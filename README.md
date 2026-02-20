# Vilage — AI Video Processing iOS App

iOS app that uploads images and processes them into AI-generated video using the Replicate API, with cloud storage via Supabase.

## Features

- **Image Upload** — pick photos from library or camera
- **AI Video Generation** — sends images to Replicate's ML models for video processing
- **Cloud Storage** — uploads and retrieves processed media from Supabase Storage
- **Async Polling** — monitors prediction status until completion

## Tech Stack

- **Swift / SwiftUI** — native iOS
- **Replicate API** — ML model inference for video generation
- **Supabase** — backend storage and authentication
- **URLSession** — async networking with JSON parsing

## Setup

1. Clone the repo
2. `pod install` (if using CocoaPods)
3. Add your API keys to the project configuration
4. Build and run in Xcode

## License

MIT
