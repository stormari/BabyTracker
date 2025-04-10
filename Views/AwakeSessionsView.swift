import SwiftUI

struct AwakeSessionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddSheet = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AwakeSession.startTime, ascending: false)],
        animation: .default)
    private var awakeSessions: FetchedResults<AwakeSession>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(awakeSessions) { session in
                    AwakeSessionRow(session: session)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Awake Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAwakeSessionView()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { awakeSessions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting awake session: \(error)")
            }
        }
    }
}

struct AwakeSessionRow: View {
    let session: AwakeSession
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "sun.max")
                    .foregroundColor(.orange)
                Text(session.startTime, style: .time)
                    .font(.headline)
                Text("-")
                Text(session.endTime ?? Date(), style: .time)
                    .font(.headline)
            }
            
            if let endTime = session.endTime {
                Text("\(Int(endTime.timeIntervalSince(session.startTime) / 60)) minutes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Ongoing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddAwakeSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isOngoing = false
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Time",
                          selection: $startTime,
                          displayedComponents: [.date, .hourAndMinute])
                
                Toggle("Still Awake", isOn: $isOngoing)
                
                if !isOngoing {
                    DatePicker("End Time",
                              selection: $endTime,
                              in: startTime...,
                              displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Awake Session")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveSession()
                }
            )
        }
    }
    
    private func saveSession() {
        let session = AwakeSession(context: viewContext)
        session.id = UUID()
        session.startTime = startTime
        session.endTime = isOngoing ? nil : endTime
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving awake session: \(error)")
        }
    }
}

#Preview {
    AwakeSessionsView()
} 