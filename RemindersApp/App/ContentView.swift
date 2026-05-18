import SwiftUI
import SwiftData

/// Root tab bar container. Houses Home, Lists, and Search tabs.
struct ContentView: View {
    @Environment(\.modelContext) private var context

    @State private var viewModel     = RemindersViewModel()
    @State private var listViewModel = ListViewModel()
    @State private var selectedTab   = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Home
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Today", systemImage: selectedTab == 0 ? "sun.max.fill" : "sun.max")
                }
                .tag(0)

            // MARK: Lists
            ListsView(viewModel: viewModel, listViewModel: listViewModel)
                .tabItem {
                    Label("Lists", systemImage: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                }
                .tag(1)

            // MARK: Search
            SearchView(viewModel: viewModel)
                .tabItem {
                    Label("Search", systemImage: selectedTab == 2 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                }
                .tag(2)
        }
        .onAppear {
            listViewModel.seedDefaultListsIfNeeded(context: context)
            Task { await NotificationManager.shared.checkAuthorizationStatus() }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Reminder.self, ReminderList.self], inMemory: true)
}
