//
//  CredentialsSection.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct CredentialsSection: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var showPassword: Bool
    
    var body: some View {
        Section(header: Text("Credentials")) {
            TextField("Username", text: $viewModel.credentials.username)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .textContentType(.username)
            
            HStack {
                if showPassword {
                    TextField("Password", text: $viewModel.credentials.password)
                        .textContentType(.password)
                } else {
                    SecureField("Password", text: $viewModel.credentials.password)
                        .textContentType(.password)
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CredentialsSection_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsSection(
            viewModel: FileTransferViewModel(),
            showPassword: .constant(true)
        )
    }
}
