# Copyright (c) 2020-2022 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

KernelVersionStr=`cat /proc/sys/kernel/osrelease`
KernelVersionS=${KernelVersionStr:2:2}
KernelVersionA=${KernelVersionStr:0:1}
KernelVersionB=${KernelVersionS%.*}

function configure_zram_parameters() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    # For >2GB Non-Go devices, size = 50% of RAM size.
    # And enable lz4 zram compression for all targets.

    let RamSizeGB="( $MemTotal / 1048576 ) + 1"
    diskSizeUnit=M

    # Set dynamic zRAM size based on RAM size
    let zRamSizeMB=2048
    if [ $RamSizeGB -ge 8 ]; then
        zRamSizeMB=6144
    elif [ $RamSizeGB -ge 6 ]; then
        zRamSizeMB=4096
    fi

    if [ -f /sys/block/zram0/disksize ]; then
        echo "$zRamSizeMB""$diskSizeUnit" > /sys/block/zram0/disksize

        # ZRAM may use more memory than it saves if SLAB_STORE_USER
        # debug option is enabled.
        if [ -e /sys/kernel/slab/zs_handle ]; then
            echo 0 > /sys/kernel/slab/zs_handle/store_user
        fi
        if [ -e /sys/kernel/slab/zspage ]; then
            echo 0 > /sys/kernel/slab/zspage/store_user
        fi

        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi
}

function configure_read_ahead_kb_values() {
    # dmpts holds below read_ahead_kb nodes if exists:
    # /sys/block/dm-0/queue/read_ahead_kb to /sys/block/dm-10/queue/read_ahead_kb
    # /sys/block/sda/queue/read_ahead_kb to /sys/block/sdh/queue/read_ahead_kb
    dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc -e sd)

    # Reduce heuristic read-ahead in exchange for I/O latency
    ra_kb=128

    if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
        echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
    fi

    if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
       echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
    fi

    for dm in $dmpts; do
        echo $ra_kb > $dm
    done
}

function disable_core_ctl() {
    if [ -f /sys/devices/system/cpu/cpu0/core_ctl/enable ]; then
        echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
    else
        echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/disable
    fi
}

function configure_memory_parameters() {
    # Set Memory parameters.
    #
    # Set per_process_reclaim tuning parameters
    # All targets will use vmpressure range 50-70,
    # All targets will use 512 pages swap size.
    #
    # Set Low memory killer minfree parameters
    # 32 bit Non-Go, all memory configurations will use 15K series
    # 32 bit Go, all memory configurations will use uLMK + Memcg
    # 64 bit will use Google default LMK series.
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # vmpressure_file_min threshold is always set slightly higher
    # than LMK minfree's last bin value for all targets. It is calculated as
    # vmpressure_file_min = (last bin - second last bin ) + last bin
    #
    # Set allocstall_threshold to 0 for all targets.
    #

    # Set swappiness to 60 for all targets
    echo 100 > /proc/sys/vm/swappiness

    # Update /proc/stat less often to reduce jitter
    echo 10 > /proc/sys/vm/stat_interval

    # Disable wsf for all targets beacause we are using efk.
    # wsf Range : 1..1000 So set to bare minimum value 1.

    configure_zram_parameters

    configure_read_ahead_kb_values

    # Tune dirty (background) memory ratio for writeback
    echo 30 > /proc/sys/vm/dirty_ratio
    echo 10 > /proc/sys/vm/dirty_background_ratio

    # Tune dirty writeback timings
    echo 1500 > /proc/sys/vm/dirty_expire_centisecs
    echo 3000 > /proc/sys/vm/dirty_writeback_centisecs

    # Disable periodic kcompactd wakeups. We do not use THP, so having many
    # huge pages is not as necessary.
    echo 0 > /proc/sys/vm/compaction_proactiveness

    # With THP enabled, the kernel greatly increases min_free_kbytes over its
    # default value. Disable THP to prevent resetting of min_free_kbytes
    # value during online/offline pages.

    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        echo never > /sys/kernel/mm/transparent_hugepage/enabled
    fi

    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}
    let RamSizeGB="( $MemTotal / 1048576 ) + 1"

    # Set the min_free_kbytes to standard kernel value
    if [ $RamSizeGB -ge 8 ]; then
        echo 11584 > /proc/sys/vm/min_free_kbytes
    elif [ $RamSizeGB -ge 4 ]; then
        echo 8192 > /proc/sys/vm/min_free_kbytes
    elif [ $RamSizeGB -ge 2 ]; then
        echo 5792 > /proc/sys/vm/min_free_kbytes
    else
        echo 4096 > /proc/sys/vm/min_free_kbytes
    fi

    # add memory limit to camera cgroup
    if [ $RamSizeGB -gt 8 ]; then
        let LimitSize=838860800
    else
        let LimitSize=524288000
    fi

    echo $LimitSize > /dev/memcg/camera/provider/memory.soft_limit_in_bytes

    # XiaoMi extra free kbytes
    extra_free_kbytes_backup_enable=`getprop persist.vendor.spc.mi_extra_free_enable`
    MIN_PERCPU_PAGELIST_HIGH_FRACTION=8

    if [ "true" = ${extra_free_kbytes_backup_enable} ]; then
        echo `cat /proc/sys/vm/min_free_kbytes` " " `cat /proc/sys/vm/watermark_scale_factor` " -1" > /sys/kernel/mi_wmark/extra_free_kbytes
        cat /proc/sys/vm/lowmem_reserve_ratio > /proc/sys/vm/lowmem_reserve_ratio

        percpu_pagelist_high_fraction=`cat /proc/sys/vm/percpu_pagelist_high_fraction`
        new_percpu_pagelist_high_fraction=${percpu_pagelist_high_fraction}
        [ ${percpu_pagelist_high_fraction} -lt ${MIN_PERCPU_PAGELIST_HIGH_FRACTION} ] && new_percpu_pagelist_high_fraction=${MIN_PERCPU_PAGELIST_HIGH_FRACTION}
        let new_percpu_pagelist_high_fraction++
        echo ${new_percpu_pagelist_high_fraction} > /proc/sys/vm/percpu_pagelist_high_fraction
        echo ${percpu_pagelist_high_fraction} > /proc/sys/vm/percpu_pagelist_high_fraction
    fi
}

function start_hbtp()
{
    # Start the Host based Touch processing but not in the power off mode.
    bootmode=`getprop ro.bootmode`
    if [ "charger" != $bootmode ]; then
        start vendor.hbtp
    fi
}

if [ -f /sys/devices/soc0/soc_id ]; then
    soc_id=`cat /sys/devices/soc0/soc_id`
else
    soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

configure_memory_parameters

# Configure RT parameters
sched_rt_runtime_ms=950
sched_rt_period_ms=1000
echo "$((${sched_rt_runtime_ms} * 1000))" > /proc/sys/kernel/sched_rt_period_us
echo "$((${sched_rt_period_ms} * 1000))" > /proc/sys/kernel/sched_rt_runtime_us

# Disable Core control on silver
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# Core control parameters for gold
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 68 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 42 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 6 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

# Set up optimized scheduler parameters for khaje-2 (SDM685)
echo 55 > /proc/sys/walt/sched_downmigrate
echo 80 > /proc/sys/walt/sched_upmigrate
echo 75 > /proc/sys/walt/sched_group_downmigrate
echo 90 > /proc/sys/walt/sched_group_upmigrate
echo 1 > /proc/sys/walt/sched_walt_rotate_big_tasks

# Set up early migrate tunables for tasks in RTG
sched_early_downmigrate=40
sched_early_upmigrate=60
echo "$((1024 * 100 / $sched_early_downmigrate))" > /proc/sys/walt/sched_early_downmigrate
echo "$((1024 * 100 / $sched_early_upmigrate))" > /proc/sys/walt/sched_early_upmigrate

# CPU busy due to task dequeue and colocation
echo 248 > /proc/sys/walt/sched_coloc_busy_hysteresis_enable_cpus
echo 400000000 > /proc/sys/walt/sched_coloc_downmigrate_ns
echo 10 10 10 10 10 10 10 10 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_busy_pct
echo 39000000 39000000 39000000 39000000 39000000 39000000 39000000 39000000 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_ns

# CPU busy due to task util on all active CPUs
echo 255 > /proc/sys/walt/sched_util_busy_hysteresis_enable_cpus
echo 1 1 72 144 216 289 361 433 > /proc/sys/walt/sched_util_busy_hyst_cpu_util
echo 8000000 8000000 8000000 8000000 8000000 8000000 8000000 8000000 > /proc/sys/walt/sched_util_busy_hyst_cpu_ns

# Set up small task packing
echo 15 > /proc/sys/walt/sched_cluster_util_thres_pct
echo 22 > /proc/sys/walt/sched_idle_enough

# set the threshold for low latency task boost feature which prioritize binder activity tasks
echo 325 > /proc/sys/walt/walt_low_latency_task_threshold

# cpuset parameters
echo 2-3 > /dev/cpuset/audio-app/cpus
echo 0-1 > /dev/cpuset/background/cpus
echo 0-6 > /dev/cpuset/foreground/cpus
echo 0-3 > /dev/cpuset/system-background/cpus
echo 0-7 > /dev/cpuset/camera-daemon/cpus
echo 0-7 > /dev/cpuset/top-app/cpus
echo 0-3 > /dev/cpuset/restricted/cpus

# uclamp parameters
echo 1 > /dev/cpuctl/camera-daemon/cpu.uclamp.latency_sensitive
echo 1 > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
echo 1 > /dev/cpuctl/foreground/cpu.uclamp.latency_sensitive
echo 1 > /dev/cpuctl/camera-daemon/cpu.uclamp.min
echo 1 > /dev/cpuctl/top-app/cpu.uclamp.min

# Setup cpu.shares to throttle background groups (bg ~ 5% sysbg ~ 5% dex2oat ~2.5%)
echo 1024 > /dev/cpuctl/background/cpu.shares
echo 1024 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/dex2oat/cpu.shares
echo 20480 > /dev/cpuctl/system/cpu.shares
echo 20480 > /dev/cpuctl/camera-daemon/cpu.shares
echo 20480 > /dev/cpuctl/foreground/cpu.shares
echo 20480 > /dev/cpuctl/nnapi-hal/cpu.shares
echo 20480 > /dev/cpuctl/rt/cpu.shares
echo 20480 > /dev/cpuctl/top-app/cpu.shares

# Turn off scheduler boost at the end
echo 0 > /proc/sys/walt/sched_boost

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

# Report max frequency to unity tasks.
echo "UnityMain,libunity.so,libfb.so,liblogic.so,libssgamesdkcronet.so" > /proc/sys/walt/sched_lib_name 
echo 255 > /proc/sys/walt/sched_lib_mask_force

# configure governor settings for silver cluster
echo "walt" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo 500 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us
echo 20000 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
echo 1516800 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
echo 691200 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
echo 1 > /sys/devices/system/cpu/cpufreq/policy0/walt/pl
echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/rtg_boost_freq

# configure governor settings for gold cluster
echo "walt" > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
echo 500 > /sys/devices/system/cpu/cpufreq/policy4/walt/up_rate_limit_us
echo 10000 > /sys/devices/system/cpu/cpufreq/policy4/walt/down_rate_limit_us
echo 1766400 > /sys/devices/system/cpu/cpufreq/policy4/walt/hispeed_freq
echo 1056000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
echo 1 > /sys/devices/system/cpu/cpufreq/policy4/walt/pl
echo 0 > /sys/devices/system/cpu/cpufreq/policy4/walt/rtg_boost_freq

# colocation V3 settings
echo 940800 > /sys/devices/system/cpu/cpufreq/policy0/walt/rtg_boost_freq
echo 51 > /proc/sys/walt/sched_min_task_util_for_boost
echo 1 > /proc/sys/walt/sched_min_task_util_for_uclamp
echo 1 > /proc/sys/walt/sched_min_task_util_for_colocation

# configure input boost settings
echo 1190000 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
echo 2 > /proc/sys/walt/input_boost/sched_boost_on_input # migrate tasks to big on input
echo 250 > /proc/sys/walt/input_boost/input_boost_ms

# configure powerkey boost settings
echo 1804800 0 0 0 2208000 0 0 0 > /proc/sys/walt/input_boost/powerkey_input_boost_freq
echo 500 > /proc/sys/walt/input_boost/powerkey_input_boost_ms

# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
    cat $device/hw_min_freq > $device/boost_freq
done

for ddrbw in $bus_dcvs/DDR/*bwmon-ddr
do
    echo "762 2086 2929 3879 5931 6881 7980" > $ddrbw/mbps_zones
    echo 4 > $ddrbw/sample_ms
    echo 85 > $ddrbw/io_percent
    echo 20 > $ddrbw/hist_memory
    echo 0 > $ddrbw/hyst_length
    echo 80 > $ddrbw/down_thres
    echo 0 > $ddrbw/guard_band_mbps
    echo 250 > $ddrbw/up_scale
    echo 1600 > $ddrbw/idle_mbps
    echo 2092000 > $ddrbw/max_freq
done

echo s2idle > /sys/power/mem_sleep
echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Disable printk logging and scheduler statistics to reduce overhead
echo "0 0 0 0" > /proc/sys/kernel/printk
echo "off" > /proc/sys/kernel/printk_devkmsg 
echo 0 > /proc/sys/kernel/sched_schedstats

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
    ;;
    *)
        echo "Enable console config to $console_config"
    ;;
esac

# Post-setup services
setprop vendor.post_boot.parsed 1
