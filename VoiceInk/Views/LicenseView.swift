import SwiftUI

struct LicenseView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("License Management")
                .font(.headline)
            
            VStack(spacing: 10) {
                Text("Premium Features Always Active")
                    .foregroundColor(.green)
                
                Text("All features are available without license restrictions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
} 