//
//  DualPaneFileView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct DualPaneFileView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    @State private var isConnectSheetPresented: Bool = false
    @State private var activePaneIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            ConnectionStatusBarView(
                isConnectSheetPresented: $isConnectSheetPresented
            )
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Content panes
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Text("TD Mouse Files")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .padding(.leading)
                        
                        SMBPane(activePaneIndex: $activePaneIndex)
                            .frame(height: geometry.size.height * 0.45)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $isConnectSheetPresented) {
            NavigationView {
                ConnectionSheetView(isPresented: $isConnectSheetPresented)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct DualPaneFileView_Previews: PreviewProvider {
    static var previews: some View {
        DualPaneFileView()
            .environmentObject(FileTransferViewModel())
    }
}
