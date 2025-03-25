import SwiftUI

struct EditConnectionView: View {
    @State private var editedConnection: SavedConnection
    @Binding var isPresented: Bool
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onSave: (SavedConnection) -> Void
    
    // Light accent color that works well in light and dark mode
    private let accentColor = Color.blue
    
    init(
        connection: SavedConnection,
        isPresented: Binding<Bool>,
        onSave: @escaping (SavedConnection) -> Void
    ) {
        _editedConnection = State(initialValue: connection)
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with modern styling
            HStack {
                Text("Edit Connection")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            
            // Form content with improved spacing
            ScrollView {
                VStack(spacing: 24) {
                    connectionDetailsSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    credentialsSection
                }
                .padding(.bottom)
            }
            .frame(maxHeight: .infinity)
            
            // Action buttons with modern styling
            buttonRow
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 400, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Validation Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Extracted View Components
    
    private var connectionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Details")
                .font(.headline)
                .foregroundColor(accentColor)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Connection name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter connection name", text: $editedConnection.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Host field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Host")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter hostname or IP address", text: $editedConnection.host)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Port field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "menubar.dock.rectangle")
                            .foregroundColor(.secondary)
                        
                        TextField("445", value: $editedConnection.port, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credentials")
                .font(.headline)
                .foregroundColor(accentColor)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Username field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter username", text: $editedConnection.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Domain field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Domain (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter domain if required", text: $editedConnection.domain)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var buttonRow: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button(action: saveConnection) {
                Label("Save Changes", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }
    
    // MARK: - Methods
    
    private func saveConnection() {
        // Validate required fields
        if editedConnection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Connection name cannot be empty"
            showingError = true
            return
        }
        
        if editedConnection.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Host cannot be empty"
            showingError = true
            return
        }
        
        if editedConnection.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Username cannot be empty"
            showingError = true
            return
        }
        
        // Save and dismiss
        onSave(editedConnection)
        isPresented = false
    }
}

// MARK: - Preview
struct EditConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        EditConnectionView(
            connection: SavedConnection(
                name: "My Server",
                host: "192.168.1.100",
                port: 445,
                username: "admin",
                domain: "workgroup"
            ),
            isPresented: .constant(true),
            onSave: { _ in }
        )
        .preferredColorScheme(.light)
        
        EditConnectionView(
            connection: SavedConnection(
                name: "My Server",
                host: "192.168.1.100",
                port: 445,
                username: "admin",
                domain: "workgroup"
            ),
            isPresented: .constant(true),
            onSave: { _ in }
        )
        .preferredColorScheme(.dark)
    }
}
