//
//  ContentView.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import SwiftUI

struct ContentView: View {
    // Zugriff auf Umgebungsvariable für Token-Status
    @Environment(\.apiTokenAvailable) var apiTokenAvailable

    var body: some View {
        NavigationSplitView {
            List {
                // Mandanten
                NavigationLink {
                    MandantenListView()
                } label: {
                    Label("Mandanten", systemImage: "person.2.fill")
                }

                // Aufträge
                NavigationLink {
                     AuftragListView() // Ziel ist jetzt die Skeleton View
                } label: {
                    Label("Aufträge", systemImage: "briefcase.fill")
                }

                 // Fälle
                 NavigationLink {
                      CaseListView() // Ziel ist jetzt die Skeleton View
                 } label: {
                     Label("Fälle", systemImage: "doc.text.fill")
                 }

                 // Schuldner
                 NavigationLink {
                      DebtorListView() // Ziel ist jetzt die Skeleton View
                 } label: {
                     Label("Schuldner", systemImage: "person.fill")
                 }

                // TODO: Weitere Links hinzufügen (Workflows etc.)

                Divider()

                 // Link zu Einstellungen (Token ändern etc.)
                 NavigationLink {
                      SettingsView(isApiTokenSet: apiTokenAvailable) // Übergibt Binding
                 } label: {
                     Label("Einstellungen", systemImage: "gear")
                 }

            }
            .listStyle(.sidebar) // macOS Seitenleisten-Stil
            .navigationTitle("InkassoApp")

        } detail: {
            Text("Bitte wähle einen Bereich aus.")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 600, minHeight: 400) // Mindestgröße für das Fenster
    }
}

#Preview {
    ContentView()
        .environment(\.apiTokenAvailable, .constant(true)) // Für Vorschau
}