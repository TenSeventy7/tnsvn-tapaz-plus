### v23.7.23.17
- Revert "vendor: Restrict boosting tasks to 35% of Silver core"
- Don't schedule UI threads as FIFO
- Define 'foreground' CPUs that matches MIUI stock for AOSP
- Make input boost longer
- Drop migration cost optimization
- Match GPU nap time on pre-fling timeout
- Affine process on scroll and pre-fling
- Force hardware composition for SF
- Revert "service: Execute child processes first after fork"
- Re-strategize migration margins
- Slightly increase group downmigrate on boosts
- Allow at least 6 tasks on Gold core before waking up all CPUs
- Increase busy thresholds for Gold CPU
- Stagger util busy hyst thresholds
- Re-tune scheduler latency tunings
- Minimize number of tasks to load balance
- Set RT runtime and period to stock kernel values

### v23.7.22.4
* Execute child processes first after fork
* Increase number of tasks to migrate
* Reduce preemptive task limit to 1/4 of a sched period
* Schedule less tasks in the same sched period
* Restrict boosting tasks to 35% of Silver core
* Tune real-time tasks period and runtime
* Disable Gentle Fair Sleepers
* Do not reduce perceived CPU capacity while idle

### v23.7.21.11
* Initial public release
