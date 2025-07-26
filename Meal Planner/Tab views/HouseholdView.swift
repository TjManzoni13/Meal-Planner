import SwiftUI

struct HouseholdView: View {
    @StateObject private var householdManager = HouseholdManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                List {
                    Section(header:
                        HStack {
                            Text("Household Information")
                                .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                        .padding(.vertical, 8)
                        .padding(.leading, 8)
                    ) {
                        if let household = householdManager.household {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Household Name:")
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(household.name ?? "My Household")
                                        .foregroundColor(.black)
                                }
                                HStack {
                                    Text("Created:")
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(household.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                                        .foregroundColor(.black)
                            }
                }
                        }
                    }
                    .listRowBackground(Color.buttonBackground) // Coral background for the box
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden) // Hide default List background
                .background(Color.appBackground) // Set List background to app color
                .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    householdManager.loadOrCreateHousehold()
                }
            }
        }
    }
}
