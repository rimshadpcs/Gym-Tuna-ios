import SwiftUI

enum CounterSheetType: Identifiable {
    case addCounter
    case options(Counter)
    case stats(Counter)
    case premium
    
    var id: String {
        switch self {
        case .addCounter:
            return "addCounter"
        case .options(let counter):
            return "options_\(counter.id)"
        case .stats(let counter):
            return "stats_\(counter.id)"
        case .premium:
            return "premium"
        }
    }
}

struct CounterView: View {
    @StateObject private var viewModel: CounterViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var activeSheet: CounterSheetType? = nil
    
    let onNavigateToSubscription: () -> Void
    
    init(
        counterRepository: CounterRepository,
        subscriptionRepository: SubscriptionRepository,
        authRepository: AuthRepository,
        onNavigateToSubscription: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: CounterViewModel(
            counterRepository: counterRepository,
            subscriptionRepository: subscriptionRepository,
            authRepository: authRepository
        ))
        self.onNavigateToSubscription = onNavigateToSubscription
    }
    
    var body: some View {
        ZStack {
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: MaterialSpacing.md) {
                    if viewModel.counters.isEmpty {
                        EmptyCountersState(onAddCounter: {
                            activeSheet = .addCounter
                        })
                        .padding(.top, 100)
                    } else {
                        ForEach(viewModel.counters) { counter in
                            CounterCard(
                                counter: counter,
                                onIncrement: {
                                    viewModel.incrementCounter(counter.id)
                                },
                                onDecrement: {
                                    viewModel.decrementCounter(counter.id)
                                },
                                onTodayCountChanged: { newCount in
                                    viewModel.updateCounterTodayCount(counter.id, newTodayCount: newCount)
                                },
                                onOptions: {
                                    print("Options tapped for counter: \(counter.name)")
                                    activeSheet = .options(counter)
                                },
                                onStats: {
                                    print("Stats tapped for counter: \(counter.name)")
                                    viewModel.loadCounterStats(counter.id)
                                    activeSheet = .stats(counter)
                                }
                            )
                        }
                    }
                    
                    if viewModel.hiddenCountersCount > 0 {
                        HiddenCountersPrompt(
                            hiddenCount: viewModel.hiddenCountersCount,
                            onUpgrade: {
                                activeSheet = .premium
                            }
                        )
                    }
                }
                .padding(.horizontal, MaterialSpacing.md)
                .padding(.top, MaterialSpacing.md)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
            }
        }
        .navigationTitle("Counters")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if viewModel.subscription.tier == .premium && viewModel.subscription.isActive {
                        activeSheet = .addCounter
                    } else if viewModel.counters.count < 1 {
                        activeSheet = .addCounter
                    } else {
                        activeSheet = .premium
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                }
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .addCounter:
                AddCounterDialog(
                    onAdd: { name in
                        viewModel.createCounter(name)
                        activeSheet = nil
                    }
                )
            case .options(let counter):
                CounterOptionsDialog(
                    counter: counter,
                    onRename: { newName in
                        let updatedCounter = Counter(
                            id: counter.id,
                            name: newName,
                            userId: counter.userId,
                            currentCount: counter.currentCount,
                            todayCount: counter.todayCount,
                            createdAt: counter.createdAt,
                            lastResetDate: counter.lastResetDate
                        )
                        viewModel.updateCounter(updatedCounter)
                        activeSheet = nil
                    },
                    onDelete: {
                        viewModel.deleteCounter(counter.id)
                        activeSheet = nil
                    }
                )
            case .stats(let counter):
                CounterStatsBottomSheet(
                    counter: counter,
                    stats: viewModel.counterStats[counter.id]
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            case .premium:
                ZStack {
                    (themeManager?.colors.background ?? LightThemeColors.background)
                        .ignoresSafeArea()
                    
                    PremiumUpgradeDialog(
                        onDismiss: {
                            activeSheet = nil
                        },
                        onUpgrade: {
                            activeSheet = nil
                            onNavigateToSubscription()
                        },
                        title: "Ready for More Counters?",
                        message: "You're tracking great! Ready to unlock unlimited counters and premium features?"
                    )
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: viewModel.showPremiumBenefits) { showPremium in
            if showPremium {
                activeSheet = .premium
                viewModel.resetPremiumBenefitsNavigation()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}