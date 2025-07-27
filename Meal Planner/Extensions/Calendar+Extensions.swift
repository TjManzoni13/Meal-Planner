//
//  Calendar+Extensions.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        // Create a new calendar instance with Monday as the first day of the week
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB") // Use UK locale which uses Monday as first day
        calendar.firstWeekday = 2 // Monday = 2
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }
} 