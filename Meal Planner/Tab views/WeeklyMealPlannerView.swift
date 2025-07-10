
import SwiftUI

struct WeeklyMealPlannerView: View {
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()
    @StateObject private var weekPlanManager = WeekPlanManager()

    @State private var selectedWeekStart: Date = Calendar.current.startOfWeek(for: Date())

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let mealSlots = ["Breakfast", "Lunch", "Dinner", "Other"]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        changeWeek(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(weekRangeText(for: selectedWeekStart))
                        .font(.headline)

                    Spacer()

                    Button(action: {
                        changeWeek(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            let date = Calendar.current.date(byAdding: .day, value: index, to: selectedWeekStart)!
                            let mealDay = dayForDate(date)
                            DayColumnView(
                                date: date,
                                mealSlots: mealSlots,
                                meals: mealManager.meals,
                                day: mealDay
                            ) { selectedMeal, slot in
                                weekPlanManager.addMeal(selectedMeal, to: mealDay, slot: slot)
                            }
                            .frame(width: 160)
                        }
                    }
                    .padding(.horizontal)
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

                Spacer()
            }
            .navigationTitle("Meal Planner")
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
            .onChange(of: householdManager.household) { household in
                if let household = household {
                    mealManager.fetchMeals(for: household)
                    weekPlanManager.fetchOrCreateWeek(for: selectedWeekStart, household: household)
                }
            }
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

struct DayColumnView: View {
    let date: Date
    let mealSlots: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shortDate(for: date))
                .font(.headline)

            ForEach(mealSlots, id: \.self) { slot in
                VStack(alignment: .leading) {
                    Text(slot)
                        .font(.subheadline)
                        .bold()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 40)
                        .overlay(
                            HStack {
                                Text("Select meal...")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                        )
                }
            }
        }
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d"
        return formatter.string(from: date)
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var calendar = self
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }
}
