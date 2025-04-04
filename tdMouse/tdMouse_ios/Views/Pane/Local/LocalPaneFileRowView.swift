//
//  LocalPaneFileRowView.swift
//  tdMouse
//
//  Created by mobile on 3/4/25.
//

import SwiftUI

struct LocalPaneFileRowView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    @State private var isDragging = false
    
    @Binding var showActionSheet: Bool
    
    let file: LocalFile
    let onTap: (LocalFile) -> Void
    
    var body: some View {
        Button {
            onTap(file)
        } label: {
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    // File icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(file.fileColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: file.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(file.fileColor)
                    }
                    
                    // File info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.system(size: 16))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            if !file.isDirectory {
                                Text(Helpers.formatFileSize(UInt64(file.size)))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let date = file.modificationDate {
                                Text(Helpers.formatDate(date))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(8)
    //            .background(Color(UIColor.systemBackground))
                .contentShape(Rectangle())
                
                Divider()
                    .frame(height: 1)
                    .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onDrag {
            isDragging = true
            
            let provider = NSItemProvider()
            
            let fileData: [String: String] = [
                "name": file.name,
                "isDirectory": file.isDirectory ? "true" : "false",
                "type": "localFile",
                "path": file.url.path
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: fileData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                provider.registerObject(jsonString as NSString, visibility: .all)
            } else {
                provider.registerObject(file.name as NSString, visibility: .all)
            }
            
            return provider
        }
    }
}

struct LocalPaneFileRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneFileRowView(
            showActionSheet: .constant(false),
            file: .init(
                name: "",
                url: .init(string: "https://www.google.com/")!,
                isDirectory: true,
                size: 30,
                modificationDate: Date()
            ),
            onTap: { _ in }
        )
        .environmentObject(LocalViewModel())
    }
}
