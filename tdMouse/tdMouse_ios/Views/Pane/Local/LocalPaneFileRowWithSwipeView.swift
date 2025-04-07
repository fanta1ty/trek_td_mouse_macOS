//
//  LocalFileRowWithSwipeView.swift
//  tdMouse
//
//  Created by mobile on 6/4/25.
//

import SwiftUI

struct LocalPaneFileRowWithSwipeView: View {
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    let file: LocalFile
    let onTap: (LocalFile) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        offset = 0
                        isSwiped = false
                    }
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 80, height: 58)
                }
                .background(Color.red)
            }
            
            // Your existing file row view
            LocalPaneFileRowView(
                file: file,
                onTap: onTap,
                onSwipe: {
                    withAnimation {
                        isSwiped.toggle()
                        offset = isSwiped ? -80 : 0
                    }
                }
            )
            .background(Color(UIColor.systemBackground))
            .offset(x: offset)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
