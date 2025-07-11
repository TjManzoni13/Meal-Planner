//
//  MealPickerSheet.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct MealPickerSheet: View {
    let meals: [Meal]
    @Binding var search: String
    var onSelect: (Meal) -> Void
    var onCreateNew: () -> Void
    var onManualIngredient: (String) -> Void = { _ in } // default for backward compatibility
    @Environment(\.dismiss) private var dismiss
    @State private var manualIngredients: String = ""
    @State private var showManualInput: Bool = false
    
    // Focus states for keyboard management
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isManualIngredientsFocused: Bool

    var filteredMeals: [Meal] {
        if search.isEmpty { return meals }
        return meals.filter { ($0.name ?? "").localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search meals...", text: $search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .padding()
                List {
                    ForEach(filteredMeals, id: \.self) { meal in
                        Button(action: { 
                            onSelect(meal)
                            dismiss() // Dismiss after selection
                        }) {
                            Text(meal.name ?? "")
                        }
                    }
                }
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create New Meal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                Button(action: { showManualInput = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Add Ingredients Manually")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                if showManualInput {
                    VStack(spacing: 8) {
                        Text("Enter ingredients (one per line):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        TextEditor(text: $manualIngredients)
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .focused($isManualIngredientsFocused)
                        
                        Button("Add to Planner") {
                            let ingredients = manualIngredients
                                .components(separatedBy: .newlines)
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                            
                            for ingredient in ingredients {
                                onManualIngredient(ingredient)
                            }
                            
                            manualIngredients = ""
                            showManualInput = false
                            dismissAllKeyboards()
                            dismiss() // Dismiss after adding manual ingredients
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manualIngredients.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Select Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissAllKeyboards()
                    }
                }
            }
        }
    }
    
    private func dismissAllKeyboards() {
        isSearchFocused = false
        isManualIngredientsFocused = false
    }
} 