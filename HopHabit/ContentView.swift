//
//  ContentView.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//


import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Your tab bar background
        appearance.backgroundColor = UIColor(named: "AccentMoon") ?? .black

        // Selected tab icon + text color (VISIBLE)
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        // Unselected tab icon + text color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeWorldView()
                .tabItem { Label("Home", systemImage: "moon.stars.fill") }
                .tag(0)

            ChecklistView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                .tag(1)

            RoutineTrackerView()
                .tabItem { Label("Practice", systemImage: "timer") }
                .tag(2)

            CalendarMoonView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(3)
        }
        .preferredColorScheme(.dark)
    }
}
#Preview {
    ContentView()
}
