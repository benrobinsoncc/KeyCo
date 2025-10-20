import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("KeyCo Keyboard")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("To enable the KeyCo keyboard:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.medium)
                        Text("Open Settings")
                    }
                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.medium)
                        Text("Go to General → Keyboard → Keyboards")
                    }
                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.medium)
                        Text("Tap \"Add New Keyboard\"")
                    }
                    HStack(alignment: .top) {
                        Text("4.")
                            .fontWeight(.medium)
                        Text("Select \"KeyCo\"")
                    }
                }
                .font(.body)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
