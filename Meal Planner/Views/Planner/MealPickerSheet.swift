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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accent)
                    .cornerRadius(8)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                List {
                    ForEach(filteredMeals, id: \.self) { meal in
                        Button(action: { 
                            onSelect(meal)
                            dismiss() // Dismiss after selection
                        }) {
                            Text(meal.name ?? "")
                                .foregroundColor(Color.mainText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.accent)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.appBackground)
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create New Meal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.buttonBackground)
                    .foregroundColor(Color.mainText)
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
                    .background(Color.buttonBackground)
                    .foregroundColor(Color.mainText)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                if showManualInput {
                    VStack(spacing: 8) {
                        Text("Enter ingredients (one per line):")
                            .font(.caption)
                            .foregroundColor(Color.mainText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ZStack {
                            Color.accent
                                .cornerRadius(8)
                            TextEditor(text: $manualIngredients)
                                .frame(height: 120)
                                .padding(.horizontal)
                                .focused($isManualIngredientsFocused)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                        
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
            .background(Color.appBackground.ignoresSafeArea())
            .foregroundColor(Color.mainText)
            .navigationTitle("Select Meal")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                dismissAllKeyboards()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.mainText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(Color.mainText)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissAllKeyboards()
                    }
                    .foregroundColor(Color.mainText)
                }
            }
        }
    }
    
    private func dismissAllKeyboards() {
        isSearchFocused = false
        isManualIngredientsFocused = false
    }
} 