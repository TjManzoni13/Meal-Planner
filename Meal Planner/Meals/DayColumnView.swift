
import SwiftUI

struct DayColumnView: View {
    let date: Date
    let mealSlots: [String]
    let meals: [Meal]
    let day: MealDay
    let onSelectMeal: (Meal, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shortDate(for: date))
                .font(.headline)

            ForEach(mealSlots, id: \.self) { slot in
                VStack(alignment: .leading) {
                    Text(slot)
                        .font(.subheadline)
                        .bold()
                    MealSlotPicker(slot: slot, day: day, meals: meals) { selectedMeal in
                        onSelectMeal(selectedMeal, slot)
                    }
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

