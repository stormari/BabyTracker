import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)
            
            AwakeSessionsView()
                .tabItem {
                    Label("Awake", systemImage: "sun.max")
                }
                .tag(1)
            
            FeedingSessionsView()
                .tabItem {
                    Label("Feeding", systemImage: "drop")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct DayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAwakeSheet = false
    @State private var showingFeedingSheet = false
    
    var body: some View {
        NavigationView {
            TimelineView()
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: { showingAwakeSheet = true }) {
                                Label("New Awake Session", systemImage: "sun.max")
                            }
                            
                            Button(action: { showingFeedingSheet = true }) {
                                Label("New Feeding", systemImage: "drop")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAwakeSheet) {
                    AddAwakeSessionView()
                }
                .sheet(isPresented: $showingFeedingSheet) {
                    AddFeedingSessionView()
                }
        }
    }
}

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AwakeSession.startTime, ascending: true)],
        predicate: NSPredicate(format: "startTime >= %@ AND startTime < %@",
                             Calendar.current.startOfDay(for: Date()) as CVarArg,
                             Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)) as CVarArg),
        animation: .default)
    private var awakeSessions: FetchedResults<AwakeSession>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingSession.time, ascending: true)],
        predicate: NSPredicate(format: "time >= %@ AND time < %@",
                             Calendar.current.startOfDay(for: Date()) as CVarArg,
                             Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)) as CVarArg),
        animation: .default)
    private var feedingSessions: FetchedResults<FeedingSession>
    
    var body: some View {
        List {
            Section(header: Text("Summary")) {
                HStack {
                    Text("Total Awake Time")
                    Spacer()
                    Text(totalAwakeTime)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Feeding Amount")
                    Spacer()
                    Text(totalFeedingAmount)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Timeline")) {
                ForEach(combinedEvents, id: \.id) { event in
                    TimelineEventRow(event: event)
                }
            }
        }
    }
    
    private var totalAwakeTime: String {
        let total = awakeSessions.reduce(0) { result, session in
            guard let endTime = session.endTime else { return result }
            return result + endTime.timeIntervalSince(session.startTime)
        }
        
        let hours = Int(total) / 3600
        let minutes = Int(total) / 60 % 60
        return "\(hours)h \(minutes)m"
    }
    
    private var totalFeedingAmount: String {
        let totalMl = feedingSessions.reduce(0) { result, session in
            return session.isBreastfeeding ? result : result + session.amount
        }
        
        let totalBreastfeeding = feedingSessions.reduce(0) { result, session in
            return session.isBreastfeeding ? result + session.breastfeedingDuration : result
        }
        
        if totalMl > 0 {
            return String(format: "%.0f ml", totalMl)
        } else {
            return "\(totalBreastfeeding) min breastfeeding"
        }
    }
    
    private var combinedEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []
        
        // Add awake sessions
        for session in awakeSessions {
            events.append(TimelineEvent(
                id: session.id?.uuidString ?? UUID().uuidString,
                time: session.startTime,
                type: .awake,
                duration: session.endTime?.timeIntervalSince(session.startTime) ?? 0,
                amount: nil
            ))
        }
        
        // Add feeding sessions
        for session in feedingSessions {
            events.append(TimelineEvent(
                id: session.id?.uuidString ?? UUID().uuidString,
                time: session.time,
                type: .feeding,
                duration: session.isBreastfeeding ? Double(session.breastfeedingDuration) : nil,
                amount: session.isBreastfeeding ? nil : session.amount
            ))
        }
        
        return events.sorted(by: { $0.time > $1.time })
    }
}

struct TimelineEvent: Identifiable {
    let id: String
    let time: Date
    let type: EventType
    let duration: Double?
    let amount: Double?
    
    enum EventType {
        case awake
        case feeding
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack {
            Image(systemName: event.type == .awake ? "sun.max" : "drop")
                .foregroundColor(event.type == .awake ? .orange : .blue)
            
            VStack(alignment: .leading) {
                Text(event.time, style: .time)
                    .font(.headline)
                
                if let duration = event.duration {
                    Text(String(format: "%.0f min", duration / 60))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let amount = event.amount {
                    Text(String(format: "%.0f ml", amount))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 