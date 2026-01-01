import SwiftUI

struct JobListView: View {
    @EnvironmentObject var jobManager: JobManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(jobManager.jobs) { job in
                    JobRowView(job: job)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            jobManager.selectedJob = job
                        }

                    if job.id != jobManager.jobs.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
        .popover(item: $jobManager.selectedJob) { job in
            JobDetailPopover(job: job)
                .environmentObject(jobManager)
        }
    }
}
