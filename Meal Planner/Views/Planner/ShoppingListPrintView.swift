//
//  ShoppingListPrintView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI
import UIKit

struct ShoppingListPrintView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shoppingListManager: ShoppingListManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Button("Save Photo") {
                            captureAndSaveShoppingList()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.buttonBackground)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .padding(.vertical)
                    
                    // Shopping list content
                    ScrollView {
                        ShoppingListPrintContent(shoppingListManager: shoppingListManager)
                            .padding()
                    }
                }
            }
            .navigationTitle("Generate Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Generate Photo")
                        .font(.title)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func captureAndSaveShoppingList() {
        // Create a view for capturing (without navigation elements)
        let shoppingListContent = ShoppingListPrintContent(shoppingListManager: shoppingListManager)
        
        // Render the view to an image
        let renderer = ImageRenderer(content: shoppingListContent)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            // Convert to proper format without alpha channel
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            defer { UIGraphicsEndImageContext() }
            
            // Fill with white background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: image.size))
            
            // Draw the image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
                // Save to photos
                UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
                print("Shopping list saved to photos!")
            }
        }
    }
}

// MARK: - Shopping List Print Content (for image capture)
struct ShoppingListPrintContent: View {
    @ObservedObject var shoppingListManager: ShoppingListManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            VStack(spacing: 12) {
                Text("Shopping List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.vertical)
            
            // Shopping list content
            VStack(spacing: 16) {
                // Usual Items Section
                let usualItems = shoppingListManager.shoppingItems
                    .filter { $0.originType == "usual" }
                let groupedUsualItems = groupItems(usualItems)
                if !groupedUsualItems.isEmpty {
                    ShoppingListPrintSection(
                        title: "Usual Items",
                        items: groupedUsualItems
                    )
                }

                // Generated Items Section
                let generatedItems = shoppingListManager.shoppingItems
                    .filter { $0.originType != "usual" && $0.originType != "manual" }
                let groupedGeneratedItems = groupItems(generatedItems)
                if !groupedGeneratedItems.isEmpty {
                    ShoppingListPrintSection(
                        title: "Generated Items",
                        items: groupedGeneratedItems
                    )
                }
                
                // Manual Items Section
                let manualItems = shoppingListManager.shoppingItems
                    .filter { $0.originType == "manual" }
                let groupedManualItems = groupItems(manualItems)
                if !groupedManualItems.isEmpty {
                    ShoppingListPrintSection(
                        title: "Manual Items",
                        items: groupedManualItems
                    )
                }
                
                // Ticked Off Items Section
                let groupedTickedItems = groupItems(shoppingListManager.tickedOffItems)
                if !groupedTickedItems.isEmpty {
                    ShoppingListPrintSection(
                        title: "Ticked Off",
                        items: groupedTickedItems
                    )
                }
            }
            .padding()
        }
        .background(Color.appBackground)
    }
    
    /// Groups items by name (case-insensitive)
    private func groupItems(_ items: [ShoppingListItem]) -> [(key: String, value: [ShoppingListItem])] {
        let grouped = Dictionary(grouping: items) { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        // Sort by name
        return grouped.sorted { $0.key < $1.key }
    }
}

// MARK: - Shopping List Print Section
struct ShoppingListPrintSection: View {
    let title: String
    let items: [(key: String, value: [ShoppingListItem])]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with yellow background (like meal plan)
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accent) // Yellow background
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Items with coral background
            VStack(spacing: 0) {
                ForEach(items, id: \.key) { group in
                    HStack {
                        Text(group.key)
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        if group.value.count > 1 {
                            Text("x\(group.value.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accent) // Yellow background
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if group.key != items.last?.key {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
            .background(Color.buttonBackground) // Coral background
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(radius: 2)
    }
} 