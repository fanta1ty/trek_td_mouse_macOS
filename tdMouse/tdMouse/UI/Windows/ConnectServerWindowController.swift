import Cocoa

class ConnectServerWindowController: NSWindowController {
    
    private let authViewController = ConnectServerViewController()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Connect to Server"
        window.center()
        
        super.init(window: window)
        self.contentViewController = authViewController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Shows the window and runs it as a modal dialog
    func runModal() -> NSApplication.ModalResponse {
        guard let window else { return .abort }
        
        NSApp.runModal(for: window)
        return .OK
    }
    
    func presentModal(from parentWindow: NSWindow, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        guard let window = self.window else { return }
        
        parentWindow.beginSheet(window) { response in
            completion(response)
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.animationBehavior = .none
    }
    
    /// Close the modal window and stop the modal session
    func closeModal() {
        guard let window else { return }
        NSApp.stopModal()
        window.close()
    }
    
    override func close() {
        NSApp.stopModal()
        super.close()
    }
}
