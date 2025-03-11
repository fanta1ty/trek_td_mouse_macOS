import Cocoa

class ActivityCell: NSTableCellView {
    let progressIndicator: NSProgressIndicator = {
        let progress = NSProgressIndicator()
        progress.isIndeterminate = false
        progress.style = .bar
        progress.controlSize = .small
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    let messageLabel: NSTextField = {
       let label = NSTextField(labelWithString: "")
        label.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cellImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()
    
    private let cellTextField: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .labelColor
        return label
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Manually set the `textField` and `imageView` properties inherited from NSTableCellView
        textField = cellTextField
        imageView = cellImageView
        
        addSubview(cellImageView)
        addSubview(cellTextField)
        addSubview(progressIndicator)
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            cellImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            cellImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cellImageView.widthAnchor.constraint(equalToConstant: 24),
            cellImageView.heightAnchor.constraint(equalToConstant: 24),
            
            cellTextField.leadingAnchor.constraint(equalTo: cellImageView.trailingAnchor, constant: 8),
            cellTextField.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            cellTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            progressIndicator.leadingAnchor.constraint(equalTo: cellTextField.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: cellTextField.trailingAnchor),
            progressIndicator.topAnchor.constraint(equalTo: cellTextField.bottomAnchor, constant: 4),
            
            messageLabel.leadingAnchor.constraint(equalTo: cellTextField.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 2),
            messageLabel.trailingAnchor.constraint(equalTo: cellTextField.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }
}
