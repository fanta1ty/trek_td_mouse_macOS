//
//  ContentView.swift
//  tdMouse (iOS)
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var transferManager = TransferManager()
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalFileViewModel()
    
    var body: some View {
        VStack {
            SingleScreenFileTransferView()
                .environmentObject(transferManager)
                .environmentObject(smbViewModel)
                .environmentObject(localViewModel)
        }
    }
}

#Preview {
    ContentView()
}
