//
//  LocalPathIndicatorView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPathIndicatorView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    Image(systemName: "house.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(getPath(), id: \.self) { component in
                        if component != getPath().first {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(component)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            }
            
            Spacer()
        }
    }
}

extension LocalPathIndicatorView {
    private func getPath() -> [String] {
        let path = viewModel.currentDirectory?.path ?? ""
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
        
        if path.starts(with: documentsDirectory) {
            let relativePath = path.replacingOccurrences(of: documentsDirectory, with: "")
            let components = relativePath.split(separator: "/").map(String.init)
            return ["Documents"] + components.filter({ !$0.isEmpty })
            
        } else if path.starts(with: downloadsDirectory) {
            let relativePath = path.replacingOccurrences(of: downloadsDirectory, with: "")
            let components = relativePath.split(separator: "/").map(String.init)
            return ["Downloads"] + components.filter({ !$0.isEmpty })
        }
        
        // Default - use last 2-3 components to avoid overly long paths
        let components = path.split(separator: "/").map(String.init)
        
        if components.count <= 3 {
            return components
        } else {
            return Array(components.suffix(2))
        }
    }
}

struct LocalPathIndicatorView_Previews: PreviewProvider {
    static var previews: some View  {
        LocalPathIndicatorView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
