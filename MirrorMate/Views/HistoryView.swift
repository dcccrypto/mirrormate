import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject private var store = SessionStore.shared
    @State private var selectedFilter: TimeFilter = .all

    enum TimeFilter: String, CaseIterable {
        case all = "All"
        case week = "Week"
        case month = "Month"
    }

    let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                if !store.sessions.isEmpty {
                    statsSection
                    filterSection
                }
                
                sessionsSection
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .onAppear {
            AppLog.info("HistoryView appeared, sessions count: \(store.sessions.count)", category: .ui)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            progressCard
            statsCards
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("Your Progress")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.contrast)
            }
            
            if store.sessions.count >= 2 {
                ProgressChart(sessions: Array(store.sessions.prefix(10)))
                    .frame(height: 180)
            } else {
                Text("Record more sessions to see your progress")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .frame(height: 100)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.xl)
    }
    
    private var statsCards: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(
                title: "Sessions",
                value: "\(store.sessions.count)",
                icon: "video.fill",
                color: AppTheme.Colors.primary
            )
            
            StatCard(
                title: "Avg Score",
                value: "\(averageScore)",
                icon: "chart.bar.fill",
                color: AppTheme.Colors.accent
            )
            
            StatCard(
                title: "Best",
                value: "\(bestScore)",
                icon: "star.fill",
                color: AppTheme.Colors.success
            )
        }
    }
    
    private var filterSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                filterButton(for: filter)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private func filterButton(for filter: TimeFilter) -> some View {
        Button(action: {
            selectedFilter = filter
            HapticFeedback.selection.trigger()
        }) {
            Text(filter.rawValue)
                .font(AppTheme.Fonts.subheadline())
                .foregroundColor(selectedFilter == filter ? .white : AppTheme.Colors.contrast)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    selectedFilter == filter ?
                    AnyShapeStyle(AppTheme.Colors.primaryGradient) :
                    AnyShapeStyle(AppTheme.Colors.tertiaryBackground)
                )
                .cornerRadius(AppTheme.CornerRadius.md)
        }
    }
    
    private var sessionsSection: some View {
        Group {
            if store.sessions.isEmpty {
                EmptyStateView.noHistory {
                    // Switch to Record tab
                    // Note: Tab selection would need to be passed as binding
                    // For now, this is just a placeholder
                }
                .padding(.top, AppTheme.Spacing.xxl)
            } else {
                LazyVGrid(columns: grid, spacing: AppTheme.Spacing.md) {
                    ForEach(filteredSessions) { session in
                        NavigationLink(destination: destination(for: session)) {
                            SessionCard(session: session)
                        }
                        .bounceButton()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
    }
    
    private var filteredSessions: [SessionRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return store.sessions.filter { session in
            switch selectedFilter {
            case .all:
                return true
            case .week:
                return calendar.isDate(session.createdAt, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(session.createdAt, equalTo: now, toGranularity: .month)
            }
        }
    }
    
    private var averageScore: Int {
        guard !store.sessions.isEmpty else { return 0 }
        let total = store.sessions.reduce(0) { $0 + $1.confidenceScore }
        return total / store.sessions.count
    }
    
    private var bestScore: Int {
        store.sessions.map(\.confidenceScore).max() ?? 0
    }

    private func destination(for session: SessionRecord) -> some View {
        if let report = session.rawReport {
            return AnyView(ResultsView(report: report))
        }
        return AnyView(Text("No report available").foregroundColor(AppTheme.Colors.secondaryText))
    }
}

// MARK: - Supporting Views

struct SessionCard: View {
    let session: SessionRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Score Badge
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(scoreColor.opacity(0.15))
                    .frame(height: 100)
                
                VStack(spacing: 4) {
                    Text("\(session.confidenceScore)")
                        .font(AppTheme.Fonts.title())
                        .foregroundColor(scoreColor)
                    
                    Image(systemName: scoreIcon)
                        .font(.system(size: 20))
                        .foregroundColor(scoreColor)
                }
            }
            
            // Tags
            if !session.impressionTags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(session.impressionTags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(AppTheme.Fonts.caption2())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.tertiaryBackground)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Date
            Text(session.createdAt, style: .relative)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.tertiaryText)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var scoreColor: Color {
        if session.confidenceScore >= 80 { return AppTheme.Colors.success }
        if session.confidenceScore >= 60 { return AppTheme.Colors.primary }
        if session.confidenceScore >= 40 { return AppTheme.Colors.accent }
        return AppTheme.Colors.warning
    }
    
    private var scoreIcon: String {
        if session.confidenceScore >= 80 { return "star.fill" }
        if session.confidenceScore >= 60 { return "hand.thumbsup.fill" }
        return "chart.line.uptrend.xyaxis"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Fonts.title2())
                .foregroundColor(AppTheme.Colors.contrast)
            
            Text(title)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}

struct ProgressChart: View {
    let sessions: [SessionRecord]
    
    var body: some View {
        Chart {
            ForEach(Array(sessions.reversed().enumerated()), id: \.offset) { index, session in
                LineMark(
                    x: .value("Session", index + 1),
                    y: .value("Score", session.confidenceScore)
                )
                .foregroundStyle(AppTheme.Colors.primaryGradient)
                .interpolationMethod(.catmullRom)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                
                AreaMark(
                    x: .value("Session", index + 1),
                    y: .value("Score", session.confidenceScore)
                )
                .foregroundStyle(AppTheme.Colors.primary.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let session = value.as(Int.self) {
                        Text("#\(session)")
                            .font(AppTheme.Fonts.caption2())
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(AppTheme.Fonts.caption2())
                    }
                }
            }
        }
    }
}

