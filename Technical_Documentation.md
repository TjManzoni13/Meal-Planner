MealManager
Fields:
@Published var meals: [Meal]: The current list of meals (observable by UI).
private let context: Reference to the Core Data context.
Data Storage:
Meals are stored in Core Data, associated with a Household.
Logic:
fetchMeals(for household: Household?): Loads all meals for a given household from Core Data, sorted by name.
addMeal(name, tags, recipe, ingredients, to household): Creates a new Meal object in Core Data, assigns it to the household, and creates Ingredient objects for each ingredient (also Core Data entities, linked to the meal).
deleteMeal(_ meal, from household): Deletes a meal from Core Data and refreshes the meal list.
meals(forTag tag: String): Returns meals whose tags match the given tag or include "all".
Data Deletion:
Meals are deleted via deleteMeal, which uses CoreDataManager.shared.delete.
WeekPlanManager
Fields:
@Published var weekPlan: WeekMealPlan?: The current week’s meal plan.
private let context: Core Data context.
Data Storage:
Week plans, days, meals, manual ingredients, and manual slot ingredients are all stored in Core Data.
Logic:
fetchOrCreateWeek(for startDate, household): Loads or creates a WeekMealPlan for the given week and household.
addMeal(_ meal, to day, slot): Adds a meal to a specific slot (breakfast, lunch, dinner, other) for a day.
removeMeal(_ meal, from day, slot): Removes a meal from a specific slot.
clearAllMeals(from day): Removes all meals from all slots for a day.
createDay(for date): Creates a new MealDay for a date.
addManualIngredient(_ name): Adds a manual ingredient to the week plan.
addManualSlotIngredient(name, slot, date): Adds a manual ingredient to a specific slot and date.
fetchManualSlotIngredients(for slot, date): Returns manual slot ingredients for a slot and date.
deleteManualSlotIngredient(_ ingredient): Deletes a manual slot ingredient.
removeDay(_ day): Deletes a day from Core Data.
toggleAlreadyHave(for day, slot): Toggles the "already have" flag for a slot on a day.
getAlreadyHave(for day, slot): Returns the "already have" flag for a slot.
setAlreadyHave(_ value, for day, slot): Sets the "already have" flag.
hasAnyAlreadyHave(for day): Checks if any slot is marked as "already have".
cleanupOldPlannerData(): Deletes week plans older than 4 weeks from the current week.
Data Deletion:
Days, manual slot ingredients, and old week plans are deleted via Core Data.
ShoppingListManager
Fields:
@Published var shoppingItems: [ShoppingListItem]: Current shopping list items.
@Published var tickedOffItems: [ShoppingListItem]: Items marked as completed.
private let context: Core Data context.
Data Storage:
Shopping list items are stored in Core Data, associated with week plans and households.
Logic:
generateShoppingList(for weekPlan, household): Clears existing generated items, adds usual items, and adds items from all relevant week plans (current and up to 4 weeks back). Saves to Core Data.
loadShoppingList(from weekPlan): Loads shopping list items from Core Data for all relevant week plans.
toggleItem(_ item): Toggles the ticked state of an item and reloads the list.
clearTickedOffItems(): Deletes all ticked-off items and marks corresponding meal slots as "already have".
addManualItem(_ name, to weekPlan): Adds a manual item to the shopping list and Core Data.
Private Helpers:
addUsualItems(from household): Adds usual items from the household to the shopping list.
addMealPlanItems(from weekPlan): Adds items from meals and manual slot ingredients, skipping slots marked as "already have".
isIngredientFromAlreadyHaveSlot(_ date, slot, weekPlan): Checks if a slot is marked as "already have".
markSlotAsAlreadyHave(for item): Marks the slot as "already have" when clearing ticked items.
saveShoppingList(to weekPlan): Associates all items with the current week plan and saves.
getAllRelevantWeekPlans(for household): Fetches week plans for the last 4 weeks and current/future weeks.
clearGeneratedItems(): Deletes generated (non-manual, non-ticked) items.
clearAllItems(): Clears all items from memory.
Data Deletion:
Items are deleted when ticked off and cleared, or when generated items are cleared.
HouseholdManager
Fields:
@Published var household: Household?: The current household.
private let context: Core Data context.
Data Storage:
Households are stored in Core Data.
Logic:
loadOrCreateHousehold(): Loads the first household from Core Data or creates a new one if none exists.
updateHouseholdName(_ newName): Updates the household’s name.
deleteHousehold(): Deletes the household from Core Data.
Data Deletion:
Household is deleted via deleteHousehold.
CoreDataManager
Singleton managing the Core Data stack.
Provides context for all Core Data operations.
saveContext(): Saves changes to Core Data.
delete(_ object): Deletes an object and saves.
Data Models (inferred from usage)
Meal: id, name, tags, recipe, household, ingredients (relationship)
Ingredient: id, name, fromManual (Bool), meal (relationship), weekPlan (relationship)
WeekMealPlan: id, weekStart, household, days (relationship), manualSlotIngredients (relationship)
MealDay: id, date, breakfasts/lunches/dinners/others (relationships), alreadyHaveBreakfast/lunch/dinner/other (Bool)
ManualSlotIngredient: id, name, slot, date, weekPlan (relationship)
ShoppingListItem: id, name, originType, originMeal, originSlot, originDate, isTicked, weekPlan (relationship)
Household: id, name, createdAt, usualItems (relationship)
Data Persistence
All main data (meals, plans, shopping lists, households) is persisted in Core Data.
Data is loaded, updated, and deleted via the managers, which use the shared Core Data context.
Data Deletion
Meals, days, week plans, shopping list items, and households are deleted via their respective manager methods, which call CoreDataManager.shared.delete.
Old week plans (older than 4 weeks) are deleted by WeekPlanManager.cleanupOldPlannerData.
Ticked-off shopping list items are deleted when cleared.

# Extensions

## Color+Theme.swift
Fields/Logic:
- Adds static color properties to `Color` for app-wide use: `appBackground`, `buttonBackground`, `mainText`, `accent`.
- Provides a hex string initializer for `Color`.
Data:
- No persistent data; used for UI theming.

## Calendar+Extensions.swift
Fields/Logic:
- Adds `startOfWeek(for:)` to `Calendar`, returning the Monday of the week for a given date (UK locale).
Data:
- No persistent data; utility for date calculations.

# Meals

## MealSlotPicker.swift
Fields:
- `slot`: The meal slot (e.g., Breakfast, Lunch).
- `@ObservedObject var day: MealDay`: The day object for the slot.
- `meals: [Meal]`: List of all meals.
- `onAdd: (Meal) -> Void`, `onRemove: (Meal) -> Void`: Callbacks for adding/removing meals.
Logic:
- Displays current meals for the slot, allows adding/removing meals via menu/buttons.
- `filteredMeals()`: Filters meals by slot/tag.
- `currentMeals()`: Returns meals for the slot from the `MealDay` object.
Data:
- Reads/writes to `MealDay` (Core Data) via callbacks.

# Tab Views

## MainTabView.swift
Fields:
- `@State private var selectedTab: Int`: Tracks the selected tab.
Logic:
- Switches between main feature views: `WeeklyMealPlannerView`, `ShoppingListView`, `MealsView`, `UsualsView`, `HouseholdView`.
- Custom tab bar with icons and color theming.
Data:
- No persistent data; manages navigation.

## UsualsView.swift
Fields:
- `@StateObject private var householdManager`: Manages household and usual items.
- `@State private var newUsualItem`: Input for new usual item.
- `@FocusState private var isUsualItemFocused`: Keyboard focus.
Logic:
- Displays, adds, and deletes usual items (stored in `Household.usualItems`).
- Uses Core Data for persistence via `HouseholdManager` and `CoreDataManager`.
Data:
- Usual items are stored in Core Data, linked to the household.
Data Deletion:
- Usual items deleted via `CoreDataManager.shared.delete`.

## ShoppingListView.swift
Fields:
- `@StateObject private var householdManager`, `weekPlanManager`, `shoppingListManager`: Manage data for shopping list.
- `@State private var newManualItem`: Input for manual shopping list item.
- `@FocusState private var isTextFieldFocused`: Keyboard focus.
Logic:
- Displays grouped shopping list items (usual, generated, ticked off).
- Allows generating, loading, toggling, and clearing items.
- Manual items can be added via text field.
- Uses `ShoppingListManager` for all data operations.
Data:
- Shopping list items are stored in Core Data, grouped by type and week plan.
Data Deletion:
- Ticked-off items can be cleared (deleted from Core Data).

## MealsView.swift, MealRowView, MealDetailView
Fields:
- `@StateObject private var householdManager`, `mealManager`: Manage meal data.
- Various state fields for new meal input, tag selection, ingredient input, recipe, and keyboard focus.
Logic:
- Allows filtering, creating, editing, and deleting meals.
- `saveMeal()`: Adds a new meal to Core Data.
- `MealRowView`: Displays meal summary, triggers detail view.
- `MealDetailView`: Allows editing/deleting a meal, including updating ingredients and tags.
Data:
- Meals and ingredients are stored in Core Data, linked to the household.
Data Deletion:
- Meals and their ingredients are deleted via `CoreDataManager.shared.delete`.

# Planner Views

## WeeklyMealPlannerView.swift
Fields:
- `@Binding var selectedTab`: For tab switching.
- `@StateObject private var householdManager`, `mealManager`, `weekPlanManager`: Manage planner data.
- State for selected week, day, and view mode (day/week).
Logic:
- Displays planner for the week, allows switching between day and week view.
- Uses `WeekPlanManager` to fetch/create week plans, add/remove meals, and clean up old data.
- Calls `cleanupOldPlannerData()` on appear.
Data:
- Week plans, days, and meal assignments are stored in Core Data.
Data Deletion:
- Old week plans are deleted by `cleanupOldPlannerData()`.

## DayColumnView.swift
Fields:
- `date`, `mealSlots`, `meals`, `day`, `onMealSelected`, `onManualIngredient`, `selectedTab`, `textColor`.
Logic:
- Displays a column for a single day, showing all meal slots and their contents.
- Uses `MealSlotView` for each slot.
- Formats date with UK-style and ordinal suffix.
Data:
- Reads/writes to `MealDay` (Core Data) via callbacks.

## MealSlotView.swift
Fields:
- `slot`, `day`, `meals`, `onMealSelected`, `onManualIngredient`, `selectedTab`, `textColor`.
Logic:
- Displays meals and manual ingredients for a slot.
- Allows toggling "Ingredients at Home" (already have), adding/removing meals and manual ingredients.
- Uses `WeekPlanManager` for all data operations.
Data:
- Meals, manual slot ingredients, and "already have" flags are stored in Core Data.
Data Deletion:
- Meals and manual slot ingredients can be deleted from Core Data.

# App Entry

## Meal_PlannerApp.swift
Fields/Logic:
- Entry point for the app. Sets up the main window and root view (`MainTabView`).
- Applies global background color.
Data:
- No persistent data; sets up the app structure.