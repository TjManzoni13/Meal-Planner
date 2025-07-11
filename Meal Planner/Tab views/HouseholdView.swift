import SwiftUI

struct HouseholdView: View {
    @StateObject private var householdManager = HouseholdManager()
    
    @State private var householdName = ""
    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberPreferences = ""

    var body: some View {
        NavigationView {
            List {
                // Household Information Section
                Section(header: Text("Household Information").font(.headline)) {
                    if let household = householdManager.household {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Household Name:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(household.name ?? "My Household")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Created:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(household.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Household Members Section
                Section(header: Text("Household Members").font(.headline)) {
                    // Placeholder for household members
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("Household sharing features coming soon")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showingAddMember = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                            
                            Text("Add Household Member")
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                }

                // App Settings Section
                Section(header: Text("App Settings").font(.headline)) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("Settings and preferences")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }

                // Data Management Section
                Section(header: Text("Data Management").font(.headline)) {
                    Button(action: {
                        // TODO: Implement data export
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            
                            Text("Export Data")
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        // TODO: Implement data import
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            
                            Text("Import Data")
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        // TODO: Implement reset functionality
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            
                            Text("Reset All Data")
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                    }
                }

                // About Section
                Section(header: Text("About").font(.headline)) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("Meal Planner v1.0")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("Help & Support")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Household")
            .sheet(isPresented: $showingAddMember) {
                AddMemberView()
            }
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
        }
    }
}

// MARK: - Add Member View
struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memberName = ""
    @State private var memberPreferences = ""
    @State private var dietaryRestrictions: [String] = []
    
    // Focus states for keyboard management
    @FocusState private var isMemberNameFocused: Bool
    @FocusState private var isMemberPreferencesFocused: Bool
    
    let availableRestrictions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "None"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Member Information").font(.headline)) {
                    TextField("Member Name", text: $memberName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isMemberNameFocused)
                        .submitLabel(.next)
                        .onSubmit {
                            isMemberPreferencesFocused = true
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dietary Preferences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $memberPreferences)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .focused($isMemberPreferencesFocused)
                    }
                }

                Section(header: Text("Dietary Restrictions").font(.headline)) {
                    ForEach(availableRestrictions, id: \.self) { restriction in
                        HStack {
                            Text(restriction)
                            Spacer()
                            if dietaryRestrictions.contains(restriction) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if dietaryRestrictions.contains(restriction) {
                                dietaryRestrictions.removeAll { $0 == restriction }
                            } else {
                                dietaryRestrictions.append(restriction)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Implement save member functionality
                        dismiss()
                    }
                    .disabled(memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissAllKeyboards()
                    }
                }
            }
            .onTapGesture {
                dismissAllKeyboards()
            }
        }
    }
    
    private func dismissAllKeyboards() {
        isMemberNameFocused = false
        isMemberPreferencesFocused = false
    }
}