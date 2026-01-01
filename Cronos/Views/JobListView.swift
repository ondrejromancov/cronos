import SwiftUI

struct JobListView: View {
    @EnvironmentObject var jobManager: JobManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(jobManager.jobs) { job in
                    JobRowView(job: job)
                        .contentShape(Rectangle())
                        .background(jobManager.selectedJob?.id == job.id ? Color.accentColor.opacity(0.2) : Color.clear)
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
                                .frame(width: 200)
                        }

                    if job.id != jobManager.jobs.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}
