import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            // Main content area
            VStack(spacing: 0) {
                // Content views
                Group {
                    switch selectedTab {
                    case 0:
                        WeeklyMealPlannerView(selectedTab: $selectedTab)
                    case 1:
                        ShoppingListView()
                    case 2:
                        MealsAndUsualsView()
                    case 3:
                        HouseholdView()
                    default:
                        WeeklyMealPlannerView(selectedTab: $selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom tab bar
                HStack(spacing: 0) {
                    TabButton(
                        title: "Plan",
                        icon: "calendar",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Shop",
                        icon: "cart",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "Meals",
                        icon: "fork.knife",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabButton(
                        title: "Household",
                        icon: "person.2.fill",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                }
                .background(Color.appBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .top
                )
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.buttonBackground : Color.black)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color.buttonBackground : Color.black)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? 
                    Color.buttonBackground.opacity(0.2) : 
                    Color.clear
            )
            .cornerRadius(8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}