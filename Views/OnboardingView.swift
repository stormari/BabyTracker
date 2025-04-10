import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var babyName = ""
    @State private var birthDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Welcome to BabyTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 50)
                
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.pink)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let's get to know your little one")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Baby's Name", text: $babyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    DatePicker("Birth Date",
                             selection: $birthDate,
                             in: ...Date(),
                             displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                }
                .padding()
                
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(babyName.isEmpty ? Color.gray : Color.blue)
                        )
                        .padding(.horizontal)
                }
                .disabled(babyName.isEmpty)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private func saveAndContinue() {
        let newBaby = Baby(context: viewContext)
        newBaby.name = babyName
        newBaby.birthDate = birthDate
        
        do {
            try viewContext.save()
            hasCompletedOnboarding = true
        } catch {
            print("Error saving baby: \(error)")
        }
    }
}

#Preview {
    OnboardingView()
} 