
import SwiftUI

struct WeeklyMealPlannerView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()
    @StateObject private var weekPlanManager = WeekPlanManager()

    @State private var selectedWeekStart: Date = Calendar.current.startOfWeek(for: Date())
    @State private var showingMealPicker = false
    @State private var selectedSlot: String = ""
    @State private var selectedDay: MealDay?

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let mealSlots = ["Breakfast", "Lunch", "Dinner", "Other"]

    var body: some View {
        NavigationView {
            VStack {
                // Week navigation header
                HStack {
                    Button(action: {
                        changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text(weekRangeText(for: selectedWeekStart))
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Button(action: {
                        changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()

                // Weekly meal grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            let date = Calendar.current.date(byAdding: .day, value: index, to: selectedWeekStart)!
                            let mealDay = dayForDate(date)
                            DayColumnView(
                                date: date,
                                mealSlots: mealSlots,
                                meals: mealManager.meals,
                                day: mealDay,
                                onMealSelected: { meal, slot in
                                    weekPlanManager.addMeal(meal, to: mealDay, slot: slot)
                                },
                                onManualIngredient: { ingredient in
                                    weekPlanManager.addManualIngredient(ingredient)
                                }
                            )
                            .frame(width: 160)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Meal Planner")
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            .onChange(of: householdManager.household) { oldValue, newValue in
                if let household = newValue {
                    mealManager.fetchMeals(for: household)
                    weekPlanManager.fetchOrCreateWeek(for: selectedWeekStart, household: household)
                }
            }
        }
    }

    // Helper function to get or create the MealDay for a given date
    private func dayForDate(_ date: Date) -> MealDay {
        if let existing = weekPlanManager.weekPlan?.days?.compactMap({ $0 as? MealDay }).first(where: { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date) }) {
            return existing
        } else {
            let newDay = weekPlanManager.createDay(for: date)
            weekPlanManager.weekPlan?.addToDays(newDay)
            CoreDataManager.shared.saveContext()
            return newDay
        }
    }

    private func changeWeek(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedWeekStart) {
            selectedWeekStart = Calendar.current.startOfWeek(for: newDate)
            if let household = householdManager.household {
                weekPlanManager.fetchOrCreateWeek(for: selectedWeekStart, household: household)
            }
        }
    }

    private func weekRangeText(for start: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Day Column View
struct DayColumnView: View {
    let date: Date
    let mealSlots: [String]
    let meals: [Meal]
    let day: MealDay
    let onMealSelected: (Meal, String) -> Void
    let onManualIngredient: (String) -> Void
    
    @State private var showingMealPicker = false
    @State private var selectedSlot: String = ""
    @State private var manualIngredient = ""
    @State private var showingManualInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            Text(shortDate(for: date))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)

            // Meal slots
            ForEach(mealSlots, id: \.self) { slot in
                MealSlotView(
                    slot: slot,
                    day: day,
                    meals: meals,
                    onMealSelected: onMealSelected,
                    onManualIngredient: onManualIngredient
                )
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Slot View
struct MealSlotView: View {
    let slot: String
    let day: MealDay
    let meals: [Meal]
    let onMealSelected: (Meal, String) -> Void
    let onManualIngredient: (String) -> Void
    
    @State private var showingMealPicker = false
    @State private var manualIngredient = ""
    @State private var showingManualInput = false
    @State private var ingredientsAlreadyHave = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slot)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Current meal display or selection button
            if let currentMeal = getCurrentMeal() {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMeal.name ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    // "Ingredients already have" checkbox
                    HStack {
                        Image(systemName: ingredientsAlreadyHave ? "checkmark.square.fill" : "square")
                            .foregroundColor(ingredientsAlreadyHave ? .green : .gray)
                            .font(.caption)
                        
                        Text("Have ingredients")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        ingredientsAlreadyHave.toggle()
                    }
                }
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
                .onTapGesture {
                    showingMealPicker = true
                }
            } else {
                Button(action: {
                    showingMealPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text("Add meal")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
    }

    private func getCurrentMeal() -> Meal? {
        switch slot.lowercased() {
        case "breakfast": return day.breakfast
        case "lunch": return day.lunch
        case "dinner": return day.dinner
        case "other": return day.other
        default: return nil
        }
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var calendar = self
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }
}
