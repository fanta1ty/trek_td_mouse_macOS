//
//  ServerDetailsSection.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct ServerDetailsSection: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        Section(header: Text("Server Details")) {
            TextField("Host", text: $viewModel.credentials.host)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            HStack {
                Text("Port:")
                TextField("445", value: $viewModel.credentials.port, format: .number)
                    .keyboardType(.numberPad)
            }
            
            TextField("Domain (optional)", text: $viewModel.credentials.domain)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
}

struct ServerDetailsSection_Preview: PreviewProvider {
    static var previews: some View {
        ServerDetailsSection(viewModel: FileTransferViewModel())
    }
}
