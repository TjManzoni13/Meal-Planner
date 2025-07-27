import SwiftUI

struct UsualsView: View {
    @StateObject private var householdManager = HouseholdManager()

    @State private var newUsualItem = ""
    
    // Focus states for keyboard management
    @FocusState private var isUsualItemFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Usual Items Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Usual Items")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    // Display existing usual items
                                    if let usuals = householdManager.household?.usualItems as? Set<UsualItem> {
                                        let sortedUsuals = Array(usuals).sorted { ($0.name ?? "") < ($1.name ?? "") }
                                        ForEach(sortedUsuals, id: \.self) { item in
                                            HStack {
                                                Image(systemName: "list.bullet")
                                                    .foregroundColor(Color.accent)
                                                    .font(.title3)
                                                
                                                Text(item.name ?? "")
                                                    .font(.title3)
                                                    .foregroundColor(.black)

                                                Spacer()
                                                
                                                Button(action: {
                                                    deleteUsualItem(item)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(Color.accent)
                                                        .font(.caption)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(Color.buttonBackground)
                                            .cornerRadius(8)
                                        }
                                    }

                                    // Add new usual item
                                    HStack {
                                        TextField("Add usual item", text: $newUsualItem)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.accent)
                                            .cornerRadius(8)
                                            .focused($isUsualItemFocused)
                                            .submitLabel(.done)
                                            .foregroundColor(.black)
                                            .onSubmit {
                                                addUsualItem()
                                            }
                                        
                                        Button("Add") {
                                            addUsualItem()
                                        }
                                        .disabled(newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                        .buttonStyle(.borderedProminent)
                                        .tint(Color.accent)
                                        .foregroundColor(.black)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Usuals")
            .navigationBarTitleDisplayMode(.inline) // Ensure title is centered
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Usuals")
                        .font(.title) // Larger navigation title
                        .foregroundColor(.black)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissAllKeyboards()
                    }
                    .foregroundColor(.black)
                }
            }
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            // Tap gesture to dismiss keyboard when tapping outside
            .onTapGesture {
                dismissAllKeyboards()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func addUsualItem() {
        guard !newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let household = householdManager.household else { return }
        
        let usualItem = UsualItem(context: CoreDataManager.shared.context)
        usualItem.id = UUID()
        usualItem.name = newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        usualItem.household = household
        
        CoreDataManager.shared.saveContext()
        newUsualItem = ""
        isUsualItemFocused = false
    }
    
    private func deleteUsualItem(_ item: UsualItem) {
        CoreDataManager.shared.delete(item)
        CoreDataManager.shared.saveContext()
    }
    
    private func dismissAllKeyboards() {
        isUsualItemFocused = false
    }
} 