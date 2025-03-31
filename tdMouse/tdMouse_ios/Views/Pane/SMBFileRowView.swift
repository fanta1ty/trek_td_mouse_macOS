//
//  SMBFileRowView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRowView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    @State private var showActionSheet: Bool = false
    
    private var fileIcon: String {
        if viewModel.isDirectory(file) { return "folder.fill" }
        else { return Helpers.iconForFile(file.name) }
    }
    
    let file: File
    let onTap: (File) -> Void
    
    var body: some View {
        Text(file.name)
    }
}


