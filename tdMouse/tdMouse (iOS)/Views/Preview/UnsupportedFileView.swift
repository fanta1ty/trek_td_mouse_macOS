//
//  UnsupportedFileView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI

struct UnsupportedFileView: View {
    let fileExtension: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("File Preview Unavailable")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(".\(fileExtension) files cannot be previewed directly.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Try downloading the file to view it in a compatible application.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Add a button to open in external app if available
            Button(action: {
                checkForCompatibleApp(extension: fileExtension)
            }) {
                Text("Open in Another App")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func checkForCompatibleApp(extension fileExt: String) {
        // This would need to be implemented to check for compatible apps
        // and open the file using UIDocumentInteractionController
        
        // Example implementation:
        // let documentController = UIDocumentInteractionController(url: fileURL)
        // documentController.presentOpenInMenu(from: .zero, in: UIView(), animated: true)
        
        // For now, we just show an alert via notification
        NotificationCenter.default.post(
            name: Notification.Name("ShowUnsupportedFileAlert"),
            object: fileExt
        )
    }
}

struct UnsupportedFileView_Previews: PreviewProvider {
    static var previews: some View {
        UnsupportedFileView(fileExtension: "xyz")
    }
}
