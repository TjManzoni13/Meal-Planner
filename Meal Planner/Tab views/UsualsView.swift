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
                    List {
                        // Usual Items Section
                        Section(header: Text("Usual Items").font(.headline).foregroundColor(.black)) {
                            if let usuals = householdManager.household?.usualItems as? Set<UsualItem> {
                                ForEach(Array(usuals), id: \.self) { item in
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        
                                        Text(item.name ?? "")
                                            .foregroundColor(.black)

                                        Spacer()
                                    }
                                }
                                .onDelete { indexSet in
                                    if let index = indexSet.first {
                                        let item = Array(usuals)[index]
                                        CoreDataManager.shared.delete(item)
                                    }
                                }
                            }

                            HStack {
                                TextField("Add usual item", text: $newUsualItem)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isUsualItemFocused)
                                    .submitLabel(.done)
                                    .foregroundColor(.black)
                                    .background(Color.accent)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        addUsualItem()
                                    }
                                Button("Add") {
                                    addUsualItem()
                                }
                                .disabled(newUsualItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(.borderedProminent)
                                .tint(Color.buttonBackground)
                                .foregroundColor(.black)
                            }
                            .listRowBackground(Color.buttonBackground)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Usuals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    
    private func dismissAllKeyboards() {
        isUsualItemFocused = false
    }
} 