//
//  ContentView.swift
//  Bons Comptes
//
//  Created by Robert Oulhen on 29/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = CampaignStore()
    @State private var selectedTab = 0
    @State private var showLaunch = true
    @State private var showImportResult = false
    @State private var importSuccess = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                CampaignListView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "creditcard.fill" : "creditcard")
                        Text(NSLocalizedString("tab_campaigns", comment: ""))
                    }
                    .tag(0)

                SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "gearshape.fill" : "gearshape")
                        Text(NSLocalizedString("tab_settings", comment: ""))
                    }
                    .tag(1)
            }
            .tint(AppTheme.primary)
            .environmentObject(store)
            .opacity(showLaunch ? 0 : 1)

            // Splash Screen
            if showLaunch {
                LaunchScreen()
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunch = false
                }
            }
        }
        .onOpenURL { url in
            importSuccess = store.importFromURL(url)
            showImportResult = true
            selectedTab = 0
        }
        .alert(
            importSuccess
                ? NSLocalizedString("import_success", comment: "")
                : NSLocalizedString("import_error", comment: ""),
            isPresented: $showImportResult
        ) {
            Button("OK") { }
        }
    }
}

// MARK: - Splash Screen
struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.headerGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "banknote")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .shadow(color: .black.opacity(0.2), radius: 10)

                Text("Bons Comptes")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)

                Text(NSLocalizedString("app_subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                opacity = 1
            }
        }
    }
}

#Preview {
    ContentView()
}
