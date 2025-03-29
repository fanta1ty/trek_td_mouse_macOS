//
//  TextPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI

struct TextPreviewView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.backgroundColor = UIColor.systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        // Enable dynamic type
        textView.adjustsFontForContentSizeCategory = true
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        Task {
            do {
                let text = try String(contentsOf: url)
                
                // Determine if we need syntax highlighting
                let fileExtension = url.pathExtension.lowercased()
                
                await MainActor.run {
                    if shouldApplySyntaxHighlighting(for: fileExtension) {
                        uiView.attributedText = applySyntaxHighlighting(to: text, fileExtension: fileExtension)
                    } else {
                        uiView.text = text
                    }
                }
            } catch {
                await MainActor.run {
                    uiView.text = "Error loading text: \(error.localizedDescription)"
                    uiView.textColor = UIColor.systemRed
                }
            }
        }
    }
    
    private func shouldApplySyntaxHighlighting(for fileExtension: String) -> Bool {
        let codeFileExtensions = ["swift", "js", "java", "c", "cpp", "py", "html", "css", "json", "xml"]
        return codeFileExtensions.contains(fileExtension)
    }
    
    private func applySyntaxHighlighting(to text: String, fileExtension: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Use regular expressions to identify syntax elements
        // This is a simplified version - a production app would use a more robust syntax highlighter
        
        // Define colors
        let keywordColor = UIColor.systemPink
        let stringColor = UIColor.systemGreen
        let commentColor = UIColor.systemGray
        let numberColor = UIColor.systemOrange
        let functionColor = UIColor.systemBlue
        
        // Apply highlighting based on file type
        switch fileExtension {
        case "swift":
            // Keywords
            highlightPattern(#"\b(func|var|let|if|else|guard|return|class|struct|enum|switch|case|import|for|while|do|try|catch|throw|self|super|extension|protocol|typealias|associatedtype|where|in|as|is|init|deinit|subscript|get|set|willSet|didSet|mutating|public|private|fileprivate|internal|open|static|final|required|optional|lazy|repeat|continue|break|fallthrough|defer|precedencegroup)\b"#, color: keywordColor, in: attributedString)
            
            // Strings
            highlightPattern(#"\".*?\""#, color: stringColor, in: attributedString)
            
            // Comments
            highlightPattern(#"//.*"#, color: commentColor, in: attributedString)
            highlightPattern(#"/\*.*?\*/"#, color: commentColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
            // Numbers
            highlightPattern(#"\b\d+(\.\d+)?\b"#, color: numberColor, in: attributedString)
            
            // Function calls
            highlightPattern(#"\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()"#, color: functionColor, in: attributedString)
            
        case "js", "java":
            // Keywords
            highlightPattern(#"\b(function|var|let|const|if|else|return|class|new|this|for|while|do|try|catch|throw|switch|case|break|continue|default|export|import|extends|implements|interface|package|private|protected|public|static|super|yield|async|await|instanceof|typeof)\b"#, color: keywordColor, in: attributedString)
            
            // Strings
            highlightPattern(#"\".*?\""#, color: stringColor, in: attributedString)
            highlightPattern(#"\'.*?\'"#, color: stringColor, in: attributedString)
            highlightPattern(#"`.*?`"#, color: stringColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
            // Comments
            highlightPattern(#"//.*"#, color: commentColor, in: attributedString)
            highlightPattern(#"/\*.*?\*/"#, color: commentColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
            // Numbers
            highlightPattern(#"\b\d+(\.\d+)?\b"#, color: numberColor, in: attributedString)
            
            // Function calls
            highlightPattern(#"\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()"#, color: functionColor, in: attributedString)
            
        case "py":
            // Keywords
            highlightPattern(#"\b(def|class|if|elif|else|for|while|return|import|from|as|try|except|finally|raise|with|global|nonlocal|lambda|pass|break|continue|yield|assert|del|is|in|not|and|or|True|False|None)\b"#, color: keywordColor, in: attributedString)
            
            // Strings
            highlightPattern(#"\".*?\""#, color: stringColor, in: attributedString)
            highlightPattern(#"\'.*?\'"#, color: stringColor, in: attributedString)
            highlightPattern(#"\"\"\".*?\"\"\""#, color: stringColor, in: attributedString, options: [.dotMatchesLineSeparators])
            highlightPattern(#"\'\'\'.*?\'\'\'"#, color: stringColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
            // Comments
            highlightPattern(#"#.*"#, color: commentColor, in: attributedString)
            
            // Numbers
            highlightPattern(#"\b\d+(\.\d+)?\b"#, color: numberColor, in: attributedString)
            
            // Function calls
            highlightPattern(#"\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()"#, color: functionColor, in: attributedString)
            
        case "html", "xml":
            // Tags
            highlightPattern(#"</?[^>]+>"#, color: keywordColor, in: attributedString)
            
            // Attributes
            highlightPattern(#"\b[a-zA-Z-]+=(?:\"[^\"]*\"|\'[^\']*\')"#, color: functionColor, in: attributedString)
            
            // Strings
            highlightPattern(#"\"[^\"]*\""#, color: stringColor, in: attributedString)
            highlightPattern(#"\'[^\']*\'"#, color: stringColor, in: attributedString)
            
            // Comments
            highlightPattern(#"<!--.*?-->"#, color: commentColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
        case "css":
            // Selectors
            highlightPattern(#"[.#]?[a-zA-Z0-9_-]+\s*\{[^}]*\}"#, color: functionColor, in: attributedString)
            
            // Properties
            highlightPattern(#"\b[a-zA-Z-]+(?=\s*:)"#, color: keywordColor, in: attributedString)
            
            // Values
            highlightPattern(#":\s*[^;]+(?=;)"#, color: stringColor, in: attributedString)
            
            // Comments
            highlightPattern(#"/\*.*?\*/"#, color: commentColor, in: attributedString, options: [.dotMatchesLineSeparators])
            
        case "json":
            // Keys
            highlightPattern(#"\"[^\"]+\"\s*:"#, color: keywordColor, in: attributedString)
            
            // Strings
            highlightPattern(#":\s*\"[^\"]*\""#, color: stringColor, in: attributedString)
            
            // Numbers
            highlightPattern(#"\b\d+(\.\d+)?\b"#, color: numberColor, in: attributedString)
            
            // Booleans and null
            highlightPattern(#"\b(true|false|null)\b"#, color: functionColor, in: attributedString)
            
        default:
            // No highlighting for unknown file types
            break
        }
        
        return attributedString
    }
    
    private func highlightPattern(_ pattern: String, color: UIColor, in attributedString: NSMutableAttributedString, options: NSRegularExpression.Options = []) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        
        let range = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: attributedString.string, options: [], range: range)
        
        for match in matches {
            attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
}
