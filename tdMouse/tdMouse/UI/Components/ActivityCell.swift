import Cocoa

class ActivityCell: NSTableCellView {
    let progressIndicator: NSProgressIndicator = {
        let progress = NSProgressIndicator()
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.controlSize = .regular
        progress.isIndeterminate = false
        progress.isHidden = true
        progress.minValue = 0
        progress.maxValue = 1
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
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
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
    
    func calculateHeight(for width: CGFloat) -> CGFloat {
        let textHeight = cellTextField.attributedStringValue.boundingRect(
            with: NSSize(width: width - 40, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin]
        ).height
        
        let messageHeight = messageLabel.attributedStringValue.boundingRect(
            with: NSSize(width: width - 40, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin]
        ).height
        
        let baseHeight: CGFloat = 20 // Spacing & padding
        return max(54, baseHeight + textHeight + messageHeight + (progressIndicator.isHidden ? 0 : 16))
    }
    
func configure(with transfer: TransferInfo) {
        textField?.stringValue = transfer.name
        messageLabel.stringValue = messageForState(transfer.state)
        
        switch transfer.state {
        case .queued:
            imageView?.image = Icons.file
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(nil)
            
        case .started(let progress):
            progressIndicator.isHidden = false
            progressIndicator.isIndeterminate = false
            progressIndicator.doubleValue = progressValue(for: progress)
            switch progress {
            case .file:
                cellImageView.image = Icons.file
            case .directory:
                cellImageView.image = Icons.folder
            }
            
        case .completed:
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(nil)
            
        case .failed:
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(nil)
        }
    }
    
    private func progressValue(for progress: TransferProgress) -> Double {
        switch progress {
        case .file(let value, _, _):
            return value
        case .directory:
            return 0 // Indeterminate progress for directories
        }
    }
    
    private func messageForState(_ state: TransferState) -> String {
        switch state {
        case .queued:
            return NSLocalizedString("Queued", comment: "")
        case .started(let progress):
            switch progress {
            case .file(let progress, let numberOfBytes, _):
                let progressBytes = ByteCountFormatter.string(
                    fromByteCount: Int64(Double(numberOfBytes) * progress),
                    countStyle: .file
                )
                let totalBytes = ByteCountFormatter.string(
                    fromByteCount: numberOfBytes,
                    countStyle: .file
                )
                return NSLocalizedString("\(progressBytes) of \(totalBytes)", comment: "")
            case .directory(let completedFiles, let fileBeingTransferred, _):
                if let fileBeingTransferred {
                    return NSLocalizedString("\(fileBeingTransferred.lastPathComponent) in progress", comment: "")
                } else {
                    return NSLocalizedString("\(completedFiles) files uploaded", comment: "")
                }
            }
        case .completed(let progress):
            switch progress {
            case .file(_, let numberOfBytes, _):
                return ByteCountFormatter.string(fromByteCount: numberOfBytes, countStyle: .file)
            case .directory(_, _, let bytesSent):
                return ByteCountFormatter.string(fromByteCount: bytesSent, countStyle: .file)
            }
        case .failed(let error):
            return error.localizedDescription
        }
    }
}
