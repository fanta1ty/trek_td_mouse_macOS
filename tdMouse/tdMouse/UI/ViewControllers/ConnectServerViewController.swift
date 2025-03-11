import Cocoa

class ConnectServerViewController: NSViewController {
    
    // UI Elements
    let displayNameField = NSTextField()
    let serverField = NSTextField()
    let portField = NSTextField()
    let usernameField = NSTextField()
    let passwordField = NSSecureTextField()
    let rememberPasswordCheckbox = NSButton(checkboxWithTitle: "Remember Password", target: nil, action: nil)
    
    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    let connectButton = NSButton(title: "Connect", target: nil, action: nil)
    
    override func loadView() {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
        
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [displayNameField, serverField, portField, usernameField, passwordField].forEach {
            $0.delegate = self
        }
        
        // Set default port value
        portField.stringValue = "445"
        
        connectButton.isEnabled = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.makeFirstResponder(serverField)
    }
    
    private func setupUI() {
        // Set text field properties
        let textFields = [displayNameField, serverField, portField, usernameField, passwordField]
        textFields.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.usesSingleLineMode = true
            $0.cell?.wraps = false
            $0.cell?.isScrollable = true
            $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        
        let labels = [
            "Display Name": displayNameField,
            "Server": serverField,
            "Port": portField,
            "Username": usernameField,
            "Password": passwordField
        ]
        
        let gridView = NSGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 10
        gridView.columnSpacing = 10
        gridView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        for (index, (labelText, textField)) in labels.enumerated() {
            let label = NSTextField(labelWithString: labelText)
            label.font = .systemFont(ofSize: 13)
            label.alignment = .right
            gridView.addRow(with: [label, textField])
            
            gridView.cell(atColumnIndex: 0, rowIndex: index).xPlacement = .trailing
            gridView.cell(atColumnIndex: 1, rowIndex: index).xPlacement = .fill
            
            // Prevent truncation
            label.setContentHuggingPriority(.required, for: .horizontal)
            textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        
        // Add Remember Password checkbox
        let checkboxContainer = NSStackView(views: [rememberPasswordCheckbox])
        checkboxContainer.orientation = .horizontal
        checkboxContainer.alignment = .leading
        
        // Add Buttons (Right Aligned)
        let buttonStackView = NSStackView(views: [cancelButton, connectButton])
        buttonStackView.orientation = .horizontal
        buttonStackView.alignment = .centerY
        buttonStackView.distribution = .equalSpacing
        buttonStackView.spacing = 10
        
        // Buttons Styling
        connectButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 90),
            connectButton.widthAnchor.constraint(equalToConstant: 90),
            cancelButton.heightAnchor.constraint(equalToConstant: 28),
            connectButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // Main Vertical Stack
        let mainStackView = NSStackView(views: [gridView, checkboxContainer, buttonStackView])
        mainStackView.orientation = .vertical
        mainStackView.alignment = .leading
        mainStackView.spacing = 15
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            // Set a fixed width to match the original dialog window
            view.widthAnchor.constraint(equalToConstant: 350),
            view.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        
    }
}

extension ConnectServerViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        connectButton.isEnabled = !serverField.stringValue.isEmpty &&
                                  !usernameField.stringValue.isEmpty &&
                                  !passwordField.stringValue.isEmpty
    }
}
