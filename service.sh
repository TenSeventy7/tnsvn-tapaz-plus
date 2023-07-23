
MODPATH=${0%/*}

write() {
	# Bail out if file does not exist
	[[ ! -f "$1" ]] && return 1

	# Make file writable in case it is not already
	chmod +w "$1" 2> /dev/null

	# Write the new value and bail if there's an error
	if ! echo "$2" > "$1" 2> /dev/null
	then
		echo "Failed: $1 → $2"
		return 1
	fi

	# Log the success
	echo "$1 → $2"
}

# Sleep for 10 seconds after booting
sleep 10

# Sync to data in the rare case a device crashes
sync

# Make entropy generation lighter on the CPU
write /proc/sys/kernel/random/urandom_min_reseed_secs 90

# Limit max perf event processing time to this much CPU usage
write /proc/sys/kernel/perf_cpu_time_max_percent 5

# Optimize I/O scheduler values
for queue in /sys/block/*/queue
do
	# Do not use I/O as a source of randomness
	write "$queue/add_random" 0

	# Disable I/O statistics accounting
	write "$queue/iostats" 0

	# Reduce heuristic read-ahead in exchange for I/O latency
	write "$queue/read_ahead_kb" 128

	# Reduce the maximum number of I/O requests in exchange for latency
	write "$queue/nr_requests" 64
done

# Mount debugfs to manage scheduler properties
mount -t debugfs debugfs /sys/kernel/debug

# Consider scheduling tasks that are eager to run
write /sys/kernel/debug/sched/features NEXT_BUDDY

# Disable Gentle Fair Sleepers
write /sys/kernel/debug/sched/features NO_GENTLE_FAIR_SLEEPERS

# Do not reduce perceived CPU capacity while idle
write /sys/kernel/debug/sched/features NO_NONTASK_CAPACITY

# Unmount debugfs after just in case Play Services detects this for Play Integrity
umount /sys/kernel/debug
