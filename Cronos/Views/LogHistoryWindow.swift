import SwiftUI

struct LogHistoryWindow: View {
    @EnvironmentObject var jobManager: JobManager

    var body: some View {
        Group {
            if let job = jobManager.selectedJobForHistory {
                LogHistoryView(job: job)
                    .navigationTitle("Log History - \(job.name)")
            } else {
                ContentUnavailableView(
                    "No Job Selected",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Select a job to view its log history")
                )
                .frame(minWidth: 400, minHeight: 300)
            }
        }
    }
}
