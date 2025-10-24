import SwiftUI
import Charts
import PostHog

struct ResultsView: View {
    let report: AnalysisReport
    @State private var animateProgress = false
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    private func formatTimestamp(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.Colors.primaryGradient)
                        .symbolEffect(.bounce, value: animateProgress)
                    
                    Text("Your Mirror Report")
                        .font(AppTheme.Fonts.title())
                        .foregroundColor(AppTheme.Colors.contrast)
                    
                    Text("Here's how you came across")
                        .font(AppTheme.Fonts.subheadline())
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                // Confidence Score - Hero Section
                VStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(AppTheme.Colors.primary.opacity(0.1), lineWidth: 20)
                            .frame(width: 200, height: 200)
                        
                        // Animated progress circle
                        Circle()
                            .trim(from: 0, to: animateProgress ? CGFloat(report.confidenceScore) / 100 : 0)
                            .stroke(AppTheme.Colors.primaryGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 1.5, bounce: 0.3).delay(0.2), value: animateProgress)
                        
                        VStack(spacing: 4) {
                            Text("\(report.confidenceScore)")
                                .font(AppTheme.Fonts.number())
                                .foregroundStyle(AppTheme.Colors.primaryGradient)
                                .contentTransition(.numericText())
                            
                            Text("Confidence")
                                .font(AppTheme.Fonts.subheadline())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                    
                    ConfidenceLabel(score: report.confidenceScore)
                }
                .padding(.vertical, AppTheme.Spacing.lg)
                
                // First Impression
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header - Centered
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.Colors.accentGradient)
                        
                        Text("First Impression")
                            .font(AppTheme.Fonts.headline())
                            .foregroundColor(AppTheme.Colors.contrast)
                        
                        Text("How you come across to others")
                            .font(AppTheme.Fonts.caption())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Tags - Centered
                    TagCloudView(tags: report.impressionTags)
                        .frame(maxWidth: .infinity)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.xl)
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Key Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                    MetricCard(
                        icon: "eye.fill",
                        title: "Eye Contact",
                        value: "\(Int(report.gaze.eyeContactPct * 100))%",
                        color: AppTheme.Colors.primary
                    )
                    
                    MetricCard(
                        icon: "waveform",
                        title: "Energy Level",
                        value: energyLevel,
                        color: AppTheme.Colors.accent
                    )
                    
                    MetricCard(
                        icon: "text.bubble.fill",
                        title: "Filler Words",
                        value: "\(totalFillerWords)",
                        color: AppTheme.Colors.warning
                    )
                    
                    MetricCard(
                        icon: "clock.fill",
                        title: "Duration",
                        value: "\(report.durationSec)s",
                        color: AppTheme.Colors.success
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Emotion Breakdown
                if !report.emotionBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(AppTheme.Colors.success)
                            Text("Emotion Breakdown")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                        }
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(report.emotionBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { emotion, percentage in
                                EmotionBar(emotion: emotion.capitalized, percentage: percentage, animated: animateProgress)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.xl)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // Tone Timeline
                if !report.toneTimeline.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("Tone Timeline")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                        }
                        
                        ToneChartView(tonePoints: report.toneTimeline)
                            .frame(height: 200)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.xl)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Vocal Analysis
                if let vocal = report.vocalAnalysis {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "waveform.badge.mic")
                                .foregroundStyle(AppTheme.Colors.accentGradient)
                            Text("Voice Analysis")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                            PremiumMetricCard(icon: "gauge.medium", title: "Pace", value: "\(vocal.paceWordsPerMin) wpm", score: Double(vocal.paceWordsPerMin) / 200.0)
                            PremiumMetricCard(icon: "speaker.wave.3", title: "Volume", value: "\(Int(vocal.volumeConsistency * 100))%", score: vocal.volumeConsistency)
                            PremiumMetricCard(icon: "waveform.path", title: "Variety", value: "\(Int(vocal.tonalVariety * 100))%", score: vocal.tonalVariety)
                            PremiumMetricCard(icon: "checkmark.seal", title: "Clarity", value: "\(Int(vocal.clarity * 100))%", score: vocal.clarity)
                            PremiumMetricCard(icon: "pause.circle", title: "Pauses", value: "\(Int(vocal.pauseEffectiveness * 100))%", score: vocal.pauseEffectiveness)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.accentGradient.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                    .strokeBorder(AppTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Body Language Analysis
                if let body = report.bodyLanguageAnalysis {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "figure.stand")
                                .foregroundStyle(AppTheme.Colors.accentGradient)
                            Text("Body Language")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                            PremiumMetricCard(icon: "figure.arms.open", title: "Posture", value: "\(Int(body.postureScore * 100))%", score: body.postureScore)
                            PremiumMetricCard(icon: "hand.raised", title: "Gestures", value: "\(Int(body.gestureNaturalness * 100))%", score: body.gestureNaturalness)
                            PremiumMetricCard(icon: "face.smiling", title: "Expression", value: "\(Int(body.facialExpressiveness * 100))%", score: body.facialExpressiveness)
                            PremiumMetricCard(icon: "eye", title: "Eye Contact", value: "\(Int(body.eyeContactPct * 100))%", score: body.eyeContactPct)
                            PremiumMetricCard(icon: "figure.walk", title: "Movement", value: "\(Int(body.movementPurpose * 100))%", score: body.movementPurpose)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.accentGradient.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                    .strokeBorder(AppTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Strengths
                if let strengths = report.strengths, !strengths.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(AppTheme.Colors.successGradient)
                            Text("Your Strengths")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(strengths.enumerated()), id: \.offset) { index, strength in
                                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "\(index + 1).circle.fill")
                                        .foregroundColor(AppTheme.Colors.success)
                                    Text(strength)
                                        .font(AppTheme.Fonts.body())
                                        .foregroundColor(AppTheme.Colors.contrast)
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.success.opacity(0.1))
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Areas for Improvement
                if let improvements = report.areasForImprovement, !improvements.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .foregroundStyle(AppTheme.Colors.primaryGradient)
                            Text("Growth Opportunities")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(improvements.enumerated()), id: \.offset) { index, improvement in
                                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "lightbulb.circle.fill")
                                        .foregroundColor(AppTheme.Colors.primary)
                                    Text(improvement)
                                        .font(AppTheme.Fonts.body())
                                        .foregroundColor(AppTheme.Colors.contrast)
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Practice Exercises
                if let exercises = report.practiceExercises, !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundStyle(AppTheme.Colors.accentGradient)
                            Text("Practice Exercises")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    HStack {
                                        Text("Exercise \(index + 1)")
                                            .font(AppTheme.Fonts.bodyMedium())
                                            .foregroundColor(AppTheme.Colors.accent)
                                        Spacer()
                                    }
                                    Text(exercise)
                                        .font(AppTheme.Fonts.body())
                                        .foregroundColor(AppTheme.Colors.contrast)
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.secondaryBackground)
                                .cornerRadius(AppTheme.CornerRadius.md)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.accentGradient.opacity(0.1))
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // PREMIUM: Key Moments Timeline
                if let moments = report.keyMoments, !moments.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "timeline.selection")
                                .foregroundStyle(AppTheme.Colors.accentGradient)
                            Text("Key Moments")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            ForEach(moments) { moment in
                                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                    VStack {
                                        Image(systemName: moment.type == "strength" ? "checkmark.circle.fill" : "info.circle.fill")
                                            .foregroundColor(moment.type == "strength" ? AppTheme.Colors.success : AppTheme.Colors.primary)
                                            .font(.system(size: 20))
                                        
                                        Text(formatTimestamp(moment.timestamp))
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(AppTheme.Colors.secondaryText)
                                    }
                                    .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(moment.type == "strength" ? "Strength" : "Opportunity")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(moment.type == "strength" ? AppTheme.Colors.success : AppTheme.Colors.primary)
                                        Text(moment.description)
                                            .font(AppTheme.Fonts.caption())
                                            .foregroundColor(AppTheme.Colors.contrast)
                                    }
                                    .padding(AppTheme.Spacing.sm)
                                    .background(AppTheme.Colors.secondaryBackground)
                                    .cornerRadius(AppTheme.CornerRadius.sm)
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .fill(AppTheme.Colors.accentGradient.opacity(0.1))
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // AI Feedback
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("AI Insights")
                            .font(AppTheme.Fonts.headline())
                            .foregroundColor(AppTheme.Colors.contrast)
                    }
                    
                    Text(report.feedback)
                        .font(AppTheme.Fonts.aiText())
                        .foregroundColor(AppTheme.Colors.contrast)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                        .fill(AppTheme.Colors.mirrorGradient.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Action Buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    Button(action: {
                        showShareSheet = true
                        HapticFeedback.success.trigger()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Results")
                        }
                    }
                    .primaryButtonStyle()
                    .accessibilityLabel("Share your analysis results")
                    .accessibilityHint("Opens share sheet to share your confidence score and feedback")
                    
                    Button(action: {
                        dismiss()
                        HapticFeedback.light.trigger()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                            Text("Back to Home")
                        }
                    }
                    .secondaryButtonStyle()
                    .accessibilityLabel("Back to home screen")
                    .accessibilityHint("Returns to the main screen")
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                    HapticFeedback.light.trigger()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showShareSheet = true
                    HapticFeedback.success.trigger()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                animateProgress = true
            }
            HapticFeedback.success.trigger()
            AppLog.info("ResultsView displayed: confidence=\(report.confidenceScore)", category: .ui)
            
            // Track results viewed
            PostHogSDK.shared.capture("results_viewed", properties: [
                "confidence_score": report.confidenceScore,
                "filler_words_count": report.fillerWords.values.reduce(0, +),
                "duration_sec": report.durationSec,
                "has_vocal_analysis": report.vocalAnalysis != nil,
                "has_body_language": report.bodyLanguageAnalysis != nil,
                "strengths_count": report.strengths?.count ?? 0,
                "improvements_count": report.areasForImprovement?.count ?? 0
            ])
        }
    }
    
    // MARK: - Share Content
    
    private func generateShareText() -> String {
        let header = "✨ MirrorMate Analysis Results\n\n"
        let confidence = "🎯 Confidence Score: \(report.confidenceScore)/100\n"
        
        let impressions = "💫 First Impression: " + report.impressionTags.prefix(3).joined(separator: ", ") + "\n"
        
        let eyeContact = "👁️ Eye Contact: \(Int(report.gaze.eyeContactPct * 100))%\n"
        
        let emotions = "😊 Emotions:\n" + report.emotionBreakdown
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "   • \($0.key.capitalized): \(Int($0.value * 100))%" }
            .joined(separator: "\n") + "\n"
        
        let fillers = "🗣️ Filler Words: \(report.fillerWords.values.reduce(0, +)) total\n"
        
        let feedback = "\n💡 Key Insight:\n\(report.feedback.prefix(200))...\n"
        
        let footer = "\n📱 Analyzed with MirrorMate - Your AI Communication Coach"
        
        return header + confidence + impressions + eyeContact + emotions + fillers + feedback + footer
    }
    
    private var energyLevel: String {
        guard !report.toneTimeline.isEmpty else { return "N/A" }
        let total = report.toneTimeline.reduce(into: 0.0) { $0 += $1.energy }
        let avgTone = total / Double(report.toneTimeline.count)
        if avgTone > 0.7 { return "High" }
        if avgTone > 0.4 { return "Medium" }
        return "Low"
    }
    
    private var totalFillerWords: Int {
        report.fillerWords.values.reduce(0, +)
    }
}

// MARK: - Supporting Views

struct ConfidenceLabel: View {
    let score: Int
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.Fonts.bodyMedium())
                .foregroundColor(color)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.md)
    }
    
    private var label: String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        if score >= 40 { return "Moderate" }
        return "Needs Work"
    }
    
    private var icon: String {
        if score >= 80 { return "star.fill" }
        if score >= 60 { return "hand.thumbsup.fill" }
        if score >= 40 { return "exclamationmark.circle.fill" }
        return "arrow.up.circle.fill"
    }
    
    private var color: Color {
        if score >= 80 { return AppTheme.Colors.success }
        if score >= 60 { return AppTheme.Colors.primary }
        if score >= 40 { return AppTheme.Colors.accent }
        return AppTheme.Colors.warning
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                Spacer()
            }
            
            Text(value)
                .font(AppTheme.Fonts.title2())
                .foregroundColor(AppTheme.Colors.contrast)
            
            Text(title)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}

struct EmotionBar: View {
    let emotion: String
    let percentage: Double
    let animated: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            HStack {
                Text(emotion)
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.contrast)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .monospacedDigit()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(AppTheme.Colors.tertiaryBackground)
                    
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(AppTheme.Colors.accentGradient)
                        .frame(width: animated ? geometry.size.width * percentage : 0)
                        .animation(.spring(duration: 1.0).delay(0.3), value: animated)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ToneChartView: View {
    let tonePoints: [AnalysisReport.TonePoint]
    
    var body: some View {
        Chart(tonePoints, id: \.t) { point in
            LineMark(
                x: .value("Time", point.t),
                y: .value("Tone", point.energy)
            )
            .foregroundStyle(AppTheme.Colors.primaryGradient)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.t),
                y: .value("Tone", point.energy)
            )
            .foregroundStyle(AppTheme.Colors.primary.opacity(0.2))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text("\(Int(seconds))s")
                            .font(AppTheme.Fonts.caption2())
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(String(format: "%.1f", val))
                            .font(AppTheme.Fonts.caption2())
                    }
                }
            }
        }
    }
}

// MARK: - Premium Metric Card
struct PremiumMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let score: Double
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(scoreColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.Colors.contrast)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.Colors.secondaryBackground)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(min(score, 1.0)), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.md)
    }
    
    private var scoreColor: Color {
        if score >= 0.8 { return AppTheme.Colors.success }
        else if score >= 0.6 { return AppTheme.Colors.primary }
        else { return AppTheme.Colors.warning }
    }
}


