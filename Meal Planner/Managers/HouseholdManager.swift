//
//  HouseholdManager.swift
//  Meal Planner
//
//  Created by Tj Manzoni on 10/07/2025.
//

import Foundation
import CoreData

class HouseholdManager: ObservableObject {
    @Published var household: Household?

    private let context = CoreDataManager.shared.context

    // MARK: - Load or Create Household

    func loadOrCreateHousehold() {
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        request.fetchLimit = 1

        do {
            if let existing = try context.fetch(request).first {
                self.household = existing
            } else {
                let newHousehold = Household(context: context)
                newHousehold.id = UUID()
                newHousehold.name = "My Household"
                newHousehold.createdAt = Date()
                CoreDataManager.shared.saveContext()
                self.household = newHousehold
            }
        } catch {
            print("Failed to load or create household: \(error)")
        }
    }

    // MARK: - Optional: Update Household Name

    func updateHouseholdName(_ newName: String) {
        household?.name = newName
        CoreDataManager.shared.saveContext()
    }

    // MARK: - Delete Household (For Reset)

    func deleteHousehold() {
        if let household = household {
            CoreDataManager.shared.delete(household)
            self.household = nil
        }
    }
}
