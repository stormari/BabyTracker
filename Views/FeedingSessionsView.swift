import SwiftUI

struct FeedingSessionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddSheet = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedingSession.time, ascending: false)],
        animation: .default)
    private var feedingSessions: FetchedResults<FeedingSession>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(feedingSessions) { session in
                    FeedingSessionRow(session: session)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Feeding Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFeedingSessionView()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { feedingSessions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting feeding session: \(error)")
            }
        }
    }
}

struct FeedingSessionRow: View {
    let session: FeedingSession
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "drop")
                    .foregroundColor(.blue)
                Text(session.time, style: .time)
                    .font(.headline)
            }
            
            if session.isBreastfeeding {
                Text("\(session.breastfeedingDuration) minutes breastfeeding")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(String(format: "%.0f ml", session.amount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddFeedingSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var time = Date()
    @State private var isBreastfeeding = false
    @State private var amount: Double = 0
    @State private var duration: Int16 = 0
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Time",
                          selection: $time,
                          displayedComponents: [.date, .hourAndMinute])
                
                Toggle("Breastfeeding", isOn: $isBreastfeeding)
                
                if isBreastfeeding {
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 0...120)
                } else {
                    HStack {
                        Text("Amount (ml)")
                        Spacer()
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("New Feeding Session")
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
        let session = FeedingSession(context: viewContext)
        session.id = UUID()
        session.time = time
        session.isBreastfeeding = isBreastfeeding
        session.amount = amount
        session.breastfeedingDuration = duration
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving feeding session: \(error)")
        }
    }
}

#Preview {
    FeedingSessionsView()
} 