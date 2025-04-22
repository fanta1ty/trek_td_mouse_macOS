import SwiftUI

struct FileTransferProgressView: View {
    @EnvironmentObject private var bleManager: BLEManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Receiving File: \(bleManager.fileTransferInfo.fileName)")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            
            HStack {
                ProgressView(value: bleManager.transferProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 8)
                
                Text("\(Int(bleManager.transferProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            if let error = bleManager.transferError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    Task {
                        do {
                            try await bleManager.startFileTransfer()
                        } catch {
                            print("Error restarting transfer: \(error)")
                        }
                    }
                }) {
                    Text("Retry")
                        .font(.footnote.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    DispatchQueue.main.async {
                        bleManager.isTransferring = false
                    }
                }) {
                    Text("Cancel")
                        .font(.footnote.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}
