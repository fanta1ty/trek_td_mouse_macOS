//
//  ContentView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileTransferViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            
            if viewModel.isConnected {
                
            } else {
                ConnectionView(viewModel: viewModel)
            }
        }
    }
}
