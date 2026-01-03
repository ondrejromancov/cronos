import Foundation

class JobScheduler {
    private var timers: [UUID: Timer] = [:]
    private let onTrigger: (UUID) -> Void
    private let jobProvider: () -> [Job]

    init(onTrigger: @escaping (UUID) -> Void, jobProvider: @escaping () -> [Job]) {
        self.onTrigger = onTrigger
        self.jobProvider = jobProvider
    }

    /// Reschedule all jobs (call after any job change)
    func reschedule(jobs: [Job]) {
        // Cancel all existing timers
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        // Schedule enabled jobs
        for job in jobs where job.isEnabled {
            scheduleNext(job: job)
        }
    }

    private func scheduleNext(job: Job) {
        let nextRun = job.schedule.nextRun()
        let interval = nextRun.timeIntervalSinceNow

        guard interval > 0 else {
            // Schedule for next occurrence if somehow in the past
            let futureRun = job.schedule.nextRun(after: Date().addingTimeInterval(1))
            scheduleTimer(for: job, at: futureRun)
            return
        }

        scheduleTimer(for: job, at: nextRun)
    }

    private func scheduleTimer(for job: Job, at fireDate: Date) {
        let jobId = job.id  // Capture only ID, not full job

        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Trigger the job
            self.onTrigger(jobId)

            // Schedule the next occurrence with CURRENT job data
            Task { @MainActor in
                // Look up current job state - only schedule if still exists and enabled
                if let currentJob = self.jobProvider().first(where: { $0.id == jobId && $0.isEnabled }) {
                    self.scheduleNext(job: currentJob)
                }
            }
        }

        // Add to run loop on main thread with .common mode so it fires during menu interactions
        RunLoop.main.add(timer, forMode: .common)
        timers[jobId] = timer
    }

    func cancelJob(_ jobId: UUID) {
        timers[jobId]?.invalidate()
        timers.removeValue(forKey: jobId)
    }

    deinit {
        timers.values.forEach { $0.invalidate() }
    }
}
