### v23.7.31.1
- Don't rotate big tasks in load balancing
- Always set tasks with prio <= 119 as high prio MVP task
- Consider tasks that go beyond early upmigrate threshold as low latency
- Re-add sched boost hint on interaction
- Drop PID affine on boosting hints other than GPU render
- Boost GPU on app/activity launch and resume
- Experiment with boosting Gold cluster on input
- Define maximum util clamps to non top-app tasks
- Adjust UClamp minimum boosting
- Completely disable sched_util_busy_hyst
- Use 50% of RAM size for AOSP ZRAM
- Write dirty pages every 30 seconds
- Boost top-app UClamp minimum on certain hints
- Use SkiaGL for HWUI rendering
- Only boost foreground tasks to Gold if exceeding packing threshold
- Set proper minimum UClamp for top-app and camera-daemon cgroup
- Disable sdm rotator downscaler
- Boost for a full second on power key press
- Do not force 'persist.sys.force_sw_gles' if GPU is present
- Set and enable expensive rendering hint
- Tune group migration margins on boost
- Allow RTGs to upmigrate earlier and downmigrate later
- Completely disable sched_util_busy_hyst
- Adaptively boost to higher frequencies on boost hint
- Boost util on task early detect
- Increase hispeed_freq by one step
- Re-adjust migration margins
- Turn off sched boosting a bit later
- Slightly increase upmigrate margins for tasks in RTG
- Revert "vendor: Allow at least 6 tasks on Gold core before waking up all CPUs"
- Revert "vendor: Increase busy thresholds for Gold CPU"
- Boost camera-daemon tasks to Gold CPUs
- Require idle CPUs for foreground tasks

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
