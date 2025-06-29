//
//  IOSBackButton.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI

struct IOSBackButton: View {
    let action: () -> Void
    let text: String
    
    init(action: @escaping () -> Void, text: String = "Back") {
        self.action = action
        self.text = text
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MaterialColors.primary)
                
                Text(text)
                    .font(.system(size: 17))
                    .foregroundColor(MaterialColors.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
        .accessibilityHint("Navigate back to the previous screen")
    }
}

// MARK: - Toolbar Back Button

struct IOSToolbarBackButton: ToolbarContent {
    let action: () -> Void
    let text: String
    
    init(action: @escaping () -> Void, text: String = "Back") {
        self.action = action
        self.text = text
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            IOSBackButton(action: action, text: text)
        }
    }
}

#Preview {
    IOSBackButton(action: {}, text: "Back")
}