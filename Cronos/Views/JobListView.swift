import SwiftUI

struct JobListView: View {
    @EnvironmentObject var jobManager: JobManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(jobManager.jobs) { job in
                    JobRowView(job: job)
                        .contentShape(Rectangle())
                        .background(
                            jobManager.selectedJob?.id == job.id
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                        .onTapGesture {
                            if jobManager.selectedJob?.id == job.id {
                                jobManager.selectedJob = nil
                            } else {
                                jobManager.selectedJob = job
                            }
                        }
                        .popover(
                            isPresented: Binding(
                                get: { jobManager.selectedJob?.id == job.id },
                                set: { if !$0 { jobManager.selectedJob = nil } }
                            ),
                            arrowEdge: .trailing
                        ) {
                            JobDetailSidebar(job: job)
                                .frame(width: 180)
                        }
                }
            }
        }
        .frame(maxHeight: 400)
    }
}
