//
//  RootView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
            RoutineListView()
                .tabItem { Label("Routines", systemImage: "list.bullet.rectangle") }
            GymsView()
                .tabItem { Label("Gyms", systemImage: "building.2") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
