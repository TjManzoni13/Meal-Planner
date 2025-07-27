//
//  MealPlanPrintView.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import SwiftUI
import CoreData
import UIKit

struct MealPlanPrintView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var householdManager = HouseholdManager()
    @StateObject private var weekPlanManager = WeekPlanManager()
    
    @State private var startDate: Date = Calendar.current.startOfWeek(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 6, to: Calendar.current.startOfWeek(for: Date())) ?? Date()
    @State private var showingDatePicker = false
    
    let mealSlots = ["Breakfast", "Lunch", "Dinner", "Other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header with date selection
                    VStack(spacing: 12) {
                        Text("Meal Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        HStack {
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.black)
                                    Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                        .foregroundColor(.black)
                                        .font(.headline)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accent)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button("Save Photo") {
                                captureAndSaveMealPlan()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.buttonBackground)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Meal plan in portrait layout
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
                                MealPlanDayPortraitCard(
                                    date: date,
                                    mealSlots: mealSlots,
                                    household: householdManager.household
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Generate Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Generate Photo")
                        .font(.title)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate)
            }
            .onAppear {
                householdManager.loadOrCreateHousehold()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func captureAndSaveMealPlan() {
        // Create a view for capturing (without navigation elements)
        let mealPlanContent = MealPlanPrintContent(
            startDate: startDate,
            endDate: endDate,
            mealSlots: mealSlots,
            household: householdManager.household
        )
        
        // Render the view to an image
        let renderer = ImageRenderer(content: mealPlanContent)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            // Convert to proper format without alpha channel
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            defer { UIGraphicsEndImageContext() }
            
            // Fill with white background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: image.size))
            
            // Draw the image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
                // Save to photos
                UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
                print("Meal plan saved to photos!")
            }
        }
    }
}

// MARK: - Meal Plan Print Content (for image capture)
struct MealPlanPrintContent: View {
    let startDate: Date
    let endDate: Date
    let mealSlots: [String]
    let household: Household?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Meal Plan")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding(.vertical)
            
            // Meal plan content
            VStack(spacing: 16) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
                    MealPlanDayPortraitCard(
                        date: date,
                        mealSlots: mealSlots,
                        household: household
                    )
                }
            }
            .padding()
        }
        .background(Color.appBackground)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Plan Day Portrait Card
struct MealPlanDayPortraitCard: View {
    let date: Date
    let mealSlots: [String]
    let household: Household?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek(for: date))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(formatDate(date))
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accent)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Meal slots
            VStack(spacing: 0) {
                ForEach(mealSlots, id: \.self) { slot in
                    MealSlotPortraitView(
                        slot: slot,
                        date: date,
                        household: household
                    )
                    
                    if slot != mealSlots.last {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
            .background(Color.buttonBackground)
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(radius: 2)
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Slot Portrait View
struct MealSlotPortraitView: View {
    let slot: String
    let date: Date
    let household: Household?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(slot)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                let meals = getMealsForSlot(slot: slot, date: date)
                if meals.isEmpty {
                    Text("—")
                        .font(.body)
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(meals, id: \.self) { meal in
                        Text(meal.name ?? "")
                            .font(.body)
                            .foregroundColor(.black)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func getMealsForSlot(slot: String, date: Date) -> [Meal] {
        guard let household = household else { 
            print("DEBUG: No household found")
            return [] 
        }
        
        // Find the week plan for this date
        let weekStart = Calendar.current.startOfWeek(for: date)
        let context = CoreDataManager.shared.context
        
        let request: NSFetchRequest<WeekMealPlan> = WeekMealPlan.fetchRequest()
        request.predicate = NSPredicate(format: "household == %@ AND weekStart == %@", household, weekStart as NSDate)
        request.fetchLimit = 1
        
        do {
            if let weekPlan = try context.fetch(request).first,
               let days = weekPlan.days as? Set<MealDay> {
                
                print("DEBUG: Found week plan for \(weekStart), with \(days.count) days")
                
                if let day = days.first(where: { 
                    guard let dayDate = $0.date else { return false }
                    return Calendar.current.isDate(dayDate, inSameDayAs: date) 
                }) {
                    print("DEBUG: Found day for \(date), slot: \(slot)")
                    
                    let meals: [Meal]
                    switch slot.lowercased() {
                    case "breakfast":
                        meals = (day.breakfasts as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                    case "lunch":
                        meals = (day.lunches as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                    case "dinner":
                        meals = (day.dinners as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                    case "other":
                        meals = (day.others as? Set<Meal>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                    default:
                        meals = []
                    }
                    
                    print("DEBUG: Found \(meals.count) meals for \(slot) on \(date)")
                    return meals
                } else {
                    print("DEBUG: No day found for \(date)")
                }
            } else {
                print("DEBUG: No week plan found for \(weekStart)")
            }
        } catch {
            print("Error fetching meals for print view: \(error)")
        }
        
        return []
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Date Range Picker View
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Select Date Range")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // Grid layout for date selection
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        VStack(alignment: .center, spacing: 8) {
                            Text("Start Date")
                                .font(.headline)
                                .foregroundColor(.black)
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.buttonBackground)
                                .cornerRadius(8)
                                .onChange(of: startDate) { _, newValue in
                                    _ = validateDateRange()
                                }
                        }
                        
                        VStack(alignment: .center, spacing: 8) {
                            Text("End Date")
                                .font(.headline)
                                .foregroundColor(.black)
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.buttonBackground)
                                .cornerRadius(8)
                                .onChange(of: endDate) { _, newValue in
                                    _ = validateDateRange()
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    if showingError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Button("Apply") {
                        if validateDateRange() {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.buttonBackground)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func validateDateRange() -> Bool {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        if daysDifference > 13 { // More than 2 weeks (14 days)
            errorMessage = "Maximum date range is 2 weeks (14 days)"
            showingError = true
            return false
        } else if daysDifference < 0 {
            errorMessage = "End date must be after start date"
            showingError = true
            return false
        } else {
            showingError = false
            return true
        }
    }
} 