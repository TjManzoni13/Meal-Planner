//
//  WeeklyMealPlannerView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI

struct WeeklyMealPlannerView: View {
    @Binding var selectedTab: Int // Add this binding for tab switching
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var mealManager = MealManager()
    @StateObject private var weekPlanManager = WeekPlanManager()

    @State private var selectedWeekStart: Date = Calendar.current.startOfWeek(for: Date())
    @State private var selectedDayIndex: Int = Calendar.current.component(.weekday, from: Date()) - 2 // Monday = 0
    @State private var isDayView: Bool = true

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let mealSlots = ["Breakfast", "Lunch", "Dinner", "Other"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ViewModeToggle(isDayView: $isDayView)
                Text("Week")
                    .font(.headline)
                    .padding(.top, 4)
                WeekNavigation(
                    selectedWeekStart: $selectedWeekStart,
                    onWeekChange: { newStart in
                        selectedWeekStart = newStart
                        selectedDayIndex = 0
                        if let household = householdManager.household {
                            weekPlanManager.fetchOrCreateWeek(for: newStart, household: household)
                        }
                    },
                    weekRangeText: weekRangeTextUK(for: selectedWeekStart)
                )
                if isDayView {
                    VStack(spacing: 8) {
                        DaySelectorView(selectedDayIndex: $selectedDayIndex, days: days)
                            .padding(.bottom, 4)
                        
                        // Current Day Button
                        Button(action: {
                            let currentDate = Date()
                            let currentWeekStart = Calendar.current.startOfWeek(for: currentDate)
                            let currentDayIndex = Calendar.current.component(.weekday, from: currentDate) - 2 // Monday = 0
                            
                            selectedWeekStart = currentWeekStart
                            selectedDayIndex = currentDayIndex
                            
                            if let household = householdManager.household {
                                weekPlanManager.fetchOrCreateWeek(for: currentWeekStart, household: household)
                            }
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Today")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    let date = Calendar.current.date(byAdding: .day, value: selectedDayIndex, to: selectedWeekStart) ?? selectedWeekStart
                    let mealDay = dayForDate(date)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
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
                                },
                                selectedTab: $selectedTab // Pass the binding
                            )
                            .environmentObject(weekPlanManager)
                            .padding()
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        // Current Week Button
                        Button(action: {
                            let currentDate = Date()
                            let currentWeekStart = Calendar.current.startOfWeek(for: currentDate)
                            
                            selectedWeekStart = currentWeekStart
                            selectedDayIndex = 0
                            
                            if let household = householdManager.household {
                                weekPlanManager.fetchOrCreateWeek(for: currentWeekStart, household: household)
                            }
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("This Week")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding(.bottom, 4)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(0..<7, id: \.self) { index in
                                    let date = Calendar.current.date(byAdding: .day, value: index, to: selectedWeekStart) ?? selectedWeekStart
                                    let mealDay = dayForDate(date)
                                    VStack(alignment: .leading, spacing: 8) {
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
                                            },
                                            selectedTab: $selectedTab // Pass the binding
                                        )
                                        .environmentObject(weekPlanManager)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Meal Planner")
            .onAppear {
                householdManager.loadOrCreateHousehold()
                // Clean up old planner data when the view appears
                weekPlanManager.cleanupOldPlannerData()
            }
            .onChange(of: householdManager.household) { oldValue, newValue in
                if let household = newValue {
                    mealManager.fetchMeals(for: household)
                    weekPlanManager.fetchOrCreateWeek(for: selectedWeekStart, household: household)
                }
            }
        }
    }
}

// MARK: - Helpers
private extension WeeklyMealPlannerView {
    func dayForDate(_ date: Date) -> MealDay {
        if let existing = weekPlanManager.weekPlan?.days?.compactMap({ $0 as? MealDay }).first(where: { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date) }) {
            return existing
        } else {
            let newDay = weekPlanManager.createDay(for: date)
            weekPlanManager.weekPlan?.addToDays(newDay)
            CoreDataManager.shared.saveContext()
            return newDay
        }
    }

    func weekRangeTextUK(for start: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
} 