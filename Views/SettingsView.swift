import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Baby.name, ascending: true)],
        animation: .default)
    private var babies: FetchedResults<Baby>
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("enableReminders") private var enableReminders = false
    @AppStorage("feedingReminderInterval") private var feedingReminderInterval = 180.0 // 3 hours in minutes
    @AppStorage("napReminderInterval") private var napReminderInterval = 120.0 // 2 hours in minutes
    
    @State private var showingEditSheet = false
    @State private var editingBaby: Baby?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Baby Information")) {
                    if let baby = babies.first {
                        BabyInfoRow(baby: baby)
                            .onTapGesture {
                                editingBaby = baby
                                showingEditSheet = true
                            }
                    }
                }
                
                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $enableReminders)
                    
                    if enableReminders {
                        VStack(alignment: .leading) {
                            Text("Feeding Reminder")
                            Slider(value: $feedingReminderInterval,
                                   in: 60...360,
                                   step: 30) {
                                Text("Feeding Interval")
                            } minimumValueLabel: {
                                Text("1h")
                            } maximumValueLabel: {
                                Text("6h")
                            }
                            Text("\(Int(feedingReminderInterval / 60))h \(Int(feedingReminderInterval.truncatingRemainder(dividingBy: 60)))m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Nap Reminder")
                            Slider(value: $napReminderInterval,
                                   in: 60...240,
                                   step: 30) {
                                Text("Nap Interval")
                            } minimumValueLabel: {
                                Text("1h")
                            } maximumValueLabel: {
                                Text("4h")
                            }
                            Text("\(Int(napReminderInterval / 60))h \(Int(napReminderInterval.truncatingRemainder(dividingBy: 60)))m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        hasCompletedOnboarding = false
                    } label: {
                        Text("Reset Onboarding")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingEditSheet) {
                if let baby = editingBaby {
                    EditBabyView(baby: baby)
                }
            }
        }
    }
}

struct BabyInfoRow: View {
    let baby: Baby
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(baby.name ?? "Unknown")
                .font(.headline)
            
            if let birthDate = baby.birthDate {
                Text("Born \(birthDate.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Age: \(ageString(from: birthDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func ageString(from date: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month, .day],
                                                  from: date,
                                                  to: Date())
        
        if let years = ageComponents.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = ageComponents.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if let days = ageComponents.day {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        
        return "Just born"
    }
}

struct EditBabyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let baby: Baby
    
    @State private var name: String
    @State private var birthDate: Date
    
    init(baby: Baby) {
        self.baby = baby
        _name = State(initialValue: baby.name ?? "")
        _birthDate = State(initialValue: baby.birthDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                
                DatePicker("Birth Date",
                          selection: $birthDate,
                          in: ...Date(),
                          displayedComponents: .date)
            }
            .navigationTitle("Edit Baby Info")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBaby()
                }
            )
        }
    }
    
    private func saveBaby() {
        baby.name = name
        baby.birthDate = birthDate
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving baby info: \(error)")
        }
    }
}

#Preview {
    SettingsView()
} 