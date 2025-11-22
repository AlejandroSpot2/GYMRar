//
//  RoutineListView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(routines, id: \.id) { r in
                    NavigationLink(r.name) { RoutineDetailView(routine: r) }
                }
                .onDelete { idx in
                    idx.map { routines[$0] }.forEach { ctx.delete($0) }
                    try? ctx.save()
                }
            }
            .navigationTitle("Routines")
            .toolbar { Button { showBuilder = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showBuilder) { RoutineBuilderView(container: ctx.container) }
        }
    }
}

private struct RoutineDetailView: View {
    @Bindable var routine: Routine

    var body: some View {
        Form {
            Section("Name") { TextField("Name", text: $routine.name) }
            Section("Days") {
                ForEach(routine.days) { day in
                    VStack(alignment: .leading) {
                        Text(day.label).font(.headline)
                        ForEach(day.items) { it in
                            Text("• \(it.exerciseName) \(it.setScheme.sets)x\(it.setScheme.repMin)-\(it.setScheme.repMax)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }.navigationTitle(routine.name)
    }
}
