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
    @EnvironmentObject var weekPlanManager: WeekPlanManager

    // Use shared state from WeekPlanManager for selected week and day
    @State private var isDayView: Bool = true
    @State private var showingPrintView = false

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let mealSlots = ["Breakfast", "Lunch", "Dinner", "Other"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea() // App-wide background
                VStack(spacing: 0) {
                    ViewModeToggle(isDayView: $isDayView)
                        .foregroundColor(.black)
                        .font(.body) // Larger toggle text
                    Text("Week")
                        .font(.title3) // Larger 'Week' label
                        .padding(.top, 4)
                        .foregroundColor(.black)
                    WeekNavigation(
                        selectedWeekStart: $weekPlanManager.selectedWeekStart,
                        onWeekChange: { newStart in
                            weekPlanManager.selectedDayIndex = 0
                            if let household = householdManager.household {
                                weekPlanManager.updateSelectedWeek(newStart, household: household)
                            }
                        },
                        weekRangeText: weekRangeTextUK(for: weekPlanManager.selectedWeekStart)
                    )
                    .foregroundColor(.black)
                    if isDayView {
                        VStack(spacing: 8) {
                            DaySelectorView(selectedDayIndex: $weekPlanManager.selectedDayIndex, days: days)
                                .padding(.bottom, 4)
                                .foregroundColor(.black)
                            
                            // Current Day Button
                            Button(action: {
                                let currentDate = Date()
                                let currentWeekStart = Calendar.current.startOfWeek(for: currentDate)
                                // Calculate the correct day index for Monday-based week
                                let calendar = Calendar.current
                                let weekday = calendar.component(.weekday, from: currentDate)
                                let currentDayIndex = (weekday + 5) % 7
                                
                                weekPlanManager.selectedDayIndex = currentDayIndex
                                
                                if let household = householdManager.household {
                                    weekPlanManager.updateSelectedWeek(currentWeekStart, household: household)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.black)
                                    Text("Today")
                                        .foregroundColor(.black)
                                        .font(.callout) // Larger Today button
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.buttonBackground) // Coral background
                                .cornerRadius(8)
                            }
                        }
                        
                        let date = Calendar.current.date(byAdding: .day, value: weekPlanManager.selectedDayIndex, to: weekPlanManager.selectedWeekStart) ?? weekPlanManager.selectedWeekStart
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
                                    selectedTab: $selectedTab,
                                    textColor: .black // Pass black text color
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
                                
                                weekPlanManager.selectedDayIndex = 0
                                
                                if let household = householdManager.household {
                                    weekPlanManager.updateSelectedWeek(currentWeekStart, household: household)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.black)
                                    Text("This Week")
                                        .foregroundColor(.black)
                                        .font(.callout) // Larger This Week button
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.buttonBackground) // Coral background
                                .cornerRadius(8)
                            }
                            .padding(.bottom, 4)
                            
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(0..<7, id: \.self) { index in
                                        let date = Calendar.current.date(byAdding: .day, value: index, to: weekPlanManager.selectedWeekStart) ?? weekPlanManager.selectedWeekStart
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
                                                selectedTab: $selectedTab,
                                                textColor: .black // Pass black text color
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
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline) // Ensure title is centered
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Meal Planner")
                        .font(.title) // Larger navigation title
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPrintView = true
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                householdManager.loadOrCreateHousehold()
                // Clean up old planner data when the view appears
                weekPlanManager.cleanupOldPlannerData()
                
                if let household = householdManager.household {
                    mealManager.fetchMeals(for: household)
                    // Use the shared selected week start, only initialize if not already set
                    if weekPlanManager.weekPlan == nil {
                        weekPlanManager.fetchOrCreateWeek(for: weekPlanManager.selectedWeekStart, household: household)
                    }
                    // Force load days relationship to ensure persistence
                    _ = weekPlanManager.weekPlan?.days?.allObjects
                }
            }
            .onChange(of: householdManager.household) { oldValue, newValue in
                if let household = newValue {
                    mealManager.fetchMeals(for: household)
                    weekPlanManager.fetchOrCreateWeek(for: weekPlanManager.selectedWeekStart, household: household)
                    // Force load days relationship to ensure persistence
                    _ = weekPlanManager.weekPlan?.days?.allObjects
                }
            }
            .sheet(isPresented: $showingPrintView) {
                MealPlanPrintView(selectedWeekStart: weekPlanManager.selectedWeekStart)
            }
        }
    }
}

// MARK: - Helpers
private extension WeeklyMealPlannerView {
    func dayForDate(_ date: Date) -> MealDay {
        // Ensure week plan is loaded
        guard let weekPlan = weekPlanManager.weekPlan else {
            let newDay = weekPlanManager.createDay(for: date)
            return newDay
        }
        
        // Look for existing day in the week plan
        if let existing = weekPlan.days?.compactMap({ $0 as? MealDay }).first(where: { 
            guard let dayDate = $0.date else { return false }
            return Calendar.current.isDate(dayDate, inSameDayAs: date) 
        }) {
            return existing
        } else {
            // Create new day and add to week plan
            let newDay = weekPlanManager.createDay(for: date)
            weekPlan.addToDays(newDay)
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