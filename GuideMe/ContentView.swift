//
//  ContentView.swift
//  GuideMe
//
//  Created by Elliot Rapp on 9/16/24.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject var variables = CrossAppVariables.shared
    @ObservedObject var silent = SilentRecorder.shared

    // Define the number of rectangles
     @State var numberOfRectangles: Int = 4
    
    @State var numberOfSections: Int = 0
    
    @State private var isPickerOpen = false
    @State private var selectedMinutes = 1
    let options = [1, 2, 3, 5, 10]

    @State var descriptionText: String = "As of now, there is no way to directly change the default background color of the TextEditor itself beyond this method. This approach gives the appearance of a custom background while maintaining the text editing functionality you need. You can adjust the opacity and color as desired to suit your app’s design."

    @State private var hue: Double = 0.0
    
    @State private var offset: Double = 0.0
    
    @State private var editMeditation: Bool = true
    
    @State private var showPermissionAlert = false
    
    var segmentsWithSectionNumbers: [(MeditationSegment, Int?)] {
        var sectionNumber = 1
        var result: [(MeditationSegment, Int?)] = []
        for segment in variables.meditationSegments {
            switch segment.type {
            case .recording:
                result.append((segment, sectionNumber))
                sectionNumber += 1
            case .silence:
                result.append((segment, nil))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: generateGrayscaleColors(offset: offset)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Start the timer to update the offset
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        withAnimation(.linear(duration: 0.05)) {
                            // Increment the offset value
                            offset += 0.005
                            if offset > 1.0 {
                                offset -= 1.0 // Keep offset within 0.0 to 1.0
                            }
                        }
                    }
                }
                .background(
                    isPickerOpen ? Color.clear.onTapGesture {
                        withAnimation {
                            isPickerOpen = false
                        }
                    } : nil
                )
            
            
            
            TabView {
                // Generate rectangles using a ForEach loop
                ForEach(0..<numberOfRectangles, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black, lineWidth: 2) // Apply stroke with color and width
                            .frame(width: 300.2, height: 500.2)
                        
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: generateColors(hue: hue)),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .onAppear {
                                // Start the timer to update the hue
                                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                                    withAnimation(.linear(duration: 3)) {
                                        // Increment the hue value
                                        hue += 0.001
                                        if hue > 1.0 {
                                            hue -= 1.0 // Keep hue within 0.0 to 1.0
                                        }
                                    }
                                }
                            }
                            .frame(width: 300, height: 500)
                            .shadow(color: .black, radius: 15, x: -10, y: 10)
                            .opacity(0.6)
                        if editMeditation {
                            VStack {
                                
                                
                                // Title for Recordings
                                Text("Recordings")
                                    .font(.title2)
                                Spacer()
                                    .frame(height: 20)
                                
                                // Check if there are recordings
                                if variables.meditationSegments.isEmpty {
                                    Text("No recordings available.")
                                        .foregroundColor(.gray)
                                        .frame(height: 300)
                                } else {
                                    // Wrap the List in a ScrollView
                                        ScrollView {
                                            VStack {
                                                ForEach(segmentsWithSectionNumbers, id: \.0.id) { item in
                                                    let segment = item.0
                                                    let sectionNumber = item.1

                                                    switch segment.type {
                                                    case .recording(let url):
                                                        // Display recording rectangle
                                                        RecordingSegmentView(
                                                            url: url,
                                                            sectionNumber: sectionNumber ?? 0,
                                                            audioRecorder: audioRecorder,
                                                            onDelete: {
                                                                deleteSegment(segment)
                                                            }
                                                        )

                                                    case .silence(let duration):
                                                        // Display silence rectangle
                                                        SilenceSegmentView(
                                                            duration: duration,
                                                            onDelete: {
                                                                deleteSegment(segment)
                                                            }
                                                        )
                                                    }
                                                }
                                            }
                                        
                                    }
                                    .frame(height: 300) // Adjust the height of the scrollable area if needed
                                }
                                
                                VStack {
                                    // Playback Controls
                                    Button(action: {
                                        if variables.isPlaying {
                                            silent.stopPlayback()
                                        } else {
                                            silent.startPlayback()
                                        }
                                    }) {
                                        Image(systemName: variables.isPlaying ? "stop.circle" : "play.circle")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(variables.isPlaying ? .red : .green)
                                    }
                                    HStack {
                                        
                                        
                                        // Recording Controls
                                        Button(action: {
                                            if audioRecorder.isRecording {
                                                // Stop recording
                                                audioRecorder.stopRecording()
                                            } else {
                                                if audioRecorder.permissionGranted {
                                                    // Start recording
                                                    audioRecorder.startRecording()
                                                } else {
                                                    showPermissionAlert = true
                                                }
                                            }
                                        }) {
                                            Image(systemName: audioRecorder.isRecording ? "stop.circle" : "mic.circle")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                                        }
                                        
                                        
                                        CustomPickerView()
                                        
                                    }
                                }
                            }
                            .alert(isPresented: $showPermissionAlert) {
                                Alert(
                                    title: Text("Microphone Access"),
                                    message: Text("Please enable microphone access in Settings to record your voice."),
                                    primaryButton: .default(Text("Settings"), action: {
                                        // Open app settings
                                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(appSettings)
                                        }
                                    }),
                                    secondaryButton: .cancel()
                                )
                            }
                        } else if editMeditation == false {
                            
                                HStack {
                                    Button(action: {
                                        // Action to add a new rectangle
                                        numberOfRectangles -= 1
                                    }) {
                                        ZStack {
                                            // Gradient Background
                                            RoundedRectangle(cornerRadius: 25) // Use RoundedRectangle to give it rounded corners
                                                .foregroundColor(.black)
                                                .opacity(0.2)
                                                .frame(width: 30, height: 30) // Match the frame size of the button
                                            
                                            // Button Icon
                                            Image(systemName: "minus.circle")
                                                .resizable()
                                                .frame(width: 20, height: 20) // Slightly smaller to fit within the gradient background
                                                .opacity(0.5)
                                                .foregroundColor(.black) // Optional: Set icon color for better contrast
                                        }
                                        .shadow(radius: 5) // Optional: Add shadow for depth
                                    }
                                    .padding(.bottom, 400)
                                    
                                    
                                    ZStack {
                                        
                                        RoundedRectangle(cornerRadius: 30)
                                            .foregroundColor(.black)
                                            .opacity(0.2)
                                            .frame(width: 150, height: 50)
                                        
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.black, lineWidth: 0.4) // Apply stroke with color and width
                                            .frame(width: 150, height: 50)
                                        Text("09/16/2024")
                                    }
                                    .padding(.bottom, 400)
                                    .padding(.trailing, 40)
                                    
                                }
                                VStack {
                                    ZStack {
                                        
                                        RoundedRectangle(cornerRadius: 30)
                                            .foregroundColor(.black)
                                            .opacity(0.2)
                                            .frame(width: 260, height: 150)
                                            .overlay(
                                                ScrollView {
                                                    
                                                    CustomTextEditor(text: $descriptionText, backgroundColor: UIColor.clear, textColor: UIColor.black)
                                                        .padding(.top, 20)
                                                        .frame(width: 240, height: 120)
                                                    
                                                    
                                                        .padding(.horizontal, 0)
                                                }
                                                    .padding(.top, 20)
                                            )
                                        
                                        
                                        Text("description")
                                            .padding(.bottom, 100)
                                            .foregroundColor(.black)
                                            .opacity(0.5)
                                        
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.black, lineWidth: 0.4) // Apply stroke with color and width
                                            .frame(width: 260, height: 150)
                                    }
                                    .padding(.bottom, 20)
                                    
                                    ZStack {
                                        Button(action: {
                                            editMeditation = true
                                        }) {
                                            // Temporary content for visibility
                                            Text("Edit")
                                                .foregroundColor(.black) // Set to clear if you want it hidden
                                                .frame(width: 260, height: 150)
                                        }
                                        .background(Color.black.opacity(0.2)) // Apply opacity only to the background
                                        // Adjust this temporarily for debugging
                                        .frame(width: 100, height: 50)
                                        .cornerRadius(20)
                                        
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 0.4) // Apply stroke with color and width
                                            .frame(width: 100, height: 50)
                                    }
                                    Spacer()
                                        .frame(height: 50)
                                }
                                
                                
                                VStack {
                                    RoundedRectangle(cornerRadius: 50)
                                        .frame(width: 250, height: 10)
                                        .padding(.top, 390)
                                        .opacity(0.3)
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 20) {
                                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                            ZStack {
                                                Image(systemName: "backward.fill")
                                                    .resizable()
                                                    .frame(width: 50, height: 20)
                                                    .opacity(0.3)
                                                    .foregroundColor(.black)
                                            }
                                        })
                                        Button(action: {
                                            if variables.isPlaying {
                                                silent.stopPlayback()
                                            } else {
                                                silent.startPlayback()
                                            }
                                        }, label: {
                                            Image(systemName: "play.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .opacity(0.3)
                                                .foregroundColor(.black)
                                            
                                            
                                        })
                                        
                                        
                                        
                                        
                                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                            Image(systemName: "forward.fill")
                                                .resizable()
                                                .frame(width: 50, height: 20)
                                                .opacity(0.3)
                                                .foregroundColor(.black)
                                        })
                                        
                                    }
                                    .padding(.top, 10)
                                }
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            Button(action: {
                // Action to add a new rectangle
                numberOfRectangles += 1
            }) {
                ZStack {
                    // Gradient Background
                    RoundedRectangle(cornerRadius: 25) // Use RoundedRectangle to give it rounded corners
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: generateColors(hue: hue)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50) // Match the frame size of the button

                    // Button Icon
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 40, height: 40) // Slightly smaller to fit within the gradient background
                        .opacity(0.5)
                        .foregroundColor(.black) // Optional: Set icon color for better contrast
                }
                .shadow(radius: 5) // Optional: Add shadow for depth
            }
            .position(x: 335, y: 690)
        }
   
    }
    
    
    func deleteSegment(_ segment: MeditationSegment) {
        if let index = variables.meditationSegments.firstIndex(where: { $0.id == segment.id }) {
            // If it's a recording, delete the actual file
            switch segment.type {
            case .recording(let url):
                audioRecorder.deleteRecording(url: url)
            case .silence:
                break
            }

            // Remove from meditationSegments
            variables.meditationSegments.remove(at: index)
        }
    }
    
    // Function to generate gradient colors within a specific hue range
    func generateColors(hue: Double) -> [Color] {
        let saturation: Double = 0.4 // Adjust for desired color intensity
         let brightness: Double = 0.6 // Adjust brightness as needed

         let hueStart: Double = 0.5   // Starting hue (cyan/green)
         let hueEnd: Double = 0.8     // Ending hue (purple)

         // Calculate the hue range, accounting for hue wrapping
         let hueRange = (hueEnd >= hueStart) ? (hueEnd - hueStart) : (1.0 - hueStart + hueEnd)

         // Map offset (0.0 to 1.0) to the hue range with smooth oscillation
         func calculateHue(phase: Double) -> Double {
             let adjustedOffset = (offset + phase).truncatingRemainder(dividingBy: 1.0)
             // Create a smooth oscillation using the cosine function
             let oscillation = 0.5 * (1 - cos(2 * .pi * adjustedOffset))
             var hue = hueStart + hueRange * oscillation
             if hue > 1.0 {
                 hue -= 1.0 // Wrap around if hue exceeds 1.0
             }
             return hue
         }

         return [
             Color(hue: calculateHue(phase: 0.0), saturation: saturation, brightness: brightness),
             Color(hue: calculateHue(phase: 0.25), saturation: saturation, brightness: brightness),
             Color(hue: calculateHue(phase: 0.5), saturation: saturation, brightness: brightness),
             Color(hue: calculateHue(phase: 0.75), saturation: saturation, brightness: brightness)
         ]    }

    
    // Function to generate grayscale colors based on the brightness offset
    func generateGrayscaleColors(offset: Double) -> [Color] {
        let saturation: Double = 0.0 // Saturation zero for grayscale
        let minBrightness: Double = 0.05 // Minimum brightness (darkest gray)
        let maxBrightness: Double = 0.2 // Maximum brightness (lightest gray)

        // Helper function to calculate brightness using sine wave
        func calculateBrightness(phase: Double) -> Double {
            let amplitude = (maxBrightness - minBrightness) / 2
            let midBrightness = (maxBrightness + minBrightness) / 2
            return midBrightness + amplitude * sin(2 * .pi * (offset + phase))
        }

        return [
            Color(hue: 0.0, saturation: saturation, brightness: calculateBrightness(phase: 0.0)),
            Color(hue: 0.0, saturation: saturation, brightness: calculateBrightness(phase: 0.55)),
            Color(hue: 0.0, saturation: saturation, brightness: calculateBrightness(phase: 0.5)),
            Color(hue: 0.0, saturation: saturation, brightness: calculateBrightness(phase: 0.75))
        ]
    }



}


struct RecordingSegmentView: View {
    let url: URL
    let sectionNumber: Int
    @ObservedObject var audioRecorder = AudioRecorder.shared
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Section # \(sectionNumber)")
                        .font(.body)
                    Text(formatDate(from: url))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
                    .frame(width: 26)

                // Play Button
                Button(action: {
                    if audioRecorder.isPlaying && audioRecorder.currentPlayingURL == url {
                        audioRecorder.stopPlayback()
                    } else {
                        audioRecorder.playRecording(url: url)
                    }
                }) {
                    Image(systemName: audioRecorder.isPlaying && audioRecorder.currentPlayingURL == url ? "stop.circle" : "play.circle")
                        .resizable()
                        .opacity(0.7)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }

                // Delete Button
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .opacity(0.7)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)

            RoundedRectangle(cornerRadius: 30)
                .foregroundColor(.black)
                .opacity(0.2)
                .frame(width: 260, height: 50)

            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.black, lineWidth: 0.4)
                .frame(width: 260, height: 50)
        }
        .padding(.horizontal)
    }
    
    // Helper function to format recording date
    func formatDate(from url: URL) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let creationDate = attributes[.creationDate] as? Date {
                return formatter.string(from: creationDate)
            }
        } catch {
            print("Could not get file attributes: \(error.localizedDescription)")
        }
        return "Unknown Date"
    }

}

struct SilenceSegmentView: View {
    let duration: Double // Duration in seconds
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Silence")
                        .font(.body)
                    Text("\(Int(duration / 60)) min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
                    .frame(width: 130)


                // Delete Button
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .opacity(0.7)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)

            RoundedRectangle(cornerRadius: 30)
                .foregroundColor(.black)
                .opacity(0.2)
                .frame(width: 260, height: 50)

            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.black, lineWidth: 0.4)
                .frame(width: 260, height: 50)
        }
        .padding(.horizontal)
    }
}







struct CustomPickerView: View {
    
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @ObservedObject var variables = CrossAppVariables.shared
    @ObservedObject var silentRecorder = SilentRecorder.shared
    
    let options = [1, 2, 3, 5, 10, 15] // Silence durations in minutes
    @State private var selectedMinutes: Int = 5 // Default value
    
    var body: some View {
        VStack {
            if variables.isPickerOpen == false {
                
                // Picker Button
                Button(action: {
                    withAnimation {
                        variables.isPickerOpen.toggle()
                    }
                }) {
                    HStack {
                        Text("\(selectedMinutes) min")
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: variables.isPickerOpen ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.black.opacity(0.2)) // Gray background with 2% opacity
                    .cornerRadius(10)
                }
                .frame(width: 100, height: 50)
            }
            
            // Picker Options
            if variables.isPickerOpen {
                VStack(spacing: 0) {
                    ScrollView {
                        ForEach(options, id: \.self) { duration in
                            Button(action: {
                                let silenceDurationInSeconds = Double(duration * 60)
                                variables.meditationSegments.append(MeditationSegment(type: .silence(silenceDurationInSeconds)))
                                withAnimation {
                                    variables.isPickerOpen = false
                                }
                                printMeditationSegments()
                            }) {
                                Text("\(duration) min")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .background(Color.black.opacity(0.2))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                }
                
            }
        }
    
    }
    func printMeditationSegments() {
        for (index, segment) in variables.meditationSegments.enumerated() {
            switch segment.type {
            case .recording:
                print("Segment \(index + 1): Recording")
            case .silence(let duration):
                print("Segment \(index + 1): Silence for \(duration) seconds")
            }
        }
    }
}



struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var backgroundColor: UIColor
    var textColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = backgroundColor
        textView.textColor = textColor
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor

        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}





#Preview {
    ContentView()
}
