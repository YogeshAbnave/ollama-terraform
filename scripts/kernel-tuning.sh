#!/bin/bash
################################################################################
# Kernel Tuning for Ollama AI Workloads
# Optimizes system for AI model inference and Docker containers
################################################################################

set -e

echo "=========================================="
echo "Applying Kernel Tuning for AI Workloads"
echo "=========================================="

# Backup original sysctl.conf
cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Create optimized sysctl configuration
cat > /etc/sysctl.d/99-ollama-tuning.conf <<'EOF'
################################################################################
# Kernel Tuning for Ollama AI Workloads
################################################################################

# Memory Management
# -----------------
# Reduce swappiness for better memory performance (AI models prefer RAM)
vm.swappiness = 10

# Increase dirty page cache for better write performance
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Increase memory map areas (important for large AI models)
vm.max_map_count = 262144

# Overcommit memory (allow more memory allocation)
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# Network Tuning
# --------------
# Increase network buffer sizes for better throughput
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216

# TCP buffer sizes (min, default, max)
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# Increase max connections
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Increase local port range
net.ipv4.ip_local_port_range = 10000 65535

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Reduce TIME_WAIT sockets
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1

# File System
# -----------
# Increase file descriptor limits
fs.file-max = 2097152
fs.nr_open = 2097152

# Increase inotify limits (for file watching)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# Process Limits
# --------------
# Increase PID limit
kernel.pid_max = 4194304

# Increase thread limit
kernel.threads-max = 4194304

# Shared Memory
# -------------
# Increase shared memory limits (important for AI models)
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Docker/Container Optimizations
# -------------------------------
# Increase netfilter connection tracking
net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576

# AIO (Async I/O) Limits
# ----------------------
# Increase async I/O limits for better disk performance
fs.aio-max-nr = 1048576

# CPU Scheduling
# --------------
# Reduce scheduler migration cost (better for CPU-intensive tasks)
kernel.sched_migration_cost_ns = 5000000

# Security (keep reasonable defaults)
# -----------------------------------
kernel.randomize_va_space = 2
EOF

echo "✓ Kernel tuning configuration created"

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-ollama-tuning.conf

echo "✓ Kernel parameters applied"

# Set system-wide limits
cat > /etc/security/limits.d/99-ollama.conf <<'EOF'
# Limits for Ollama AI Workloads

# Increase open file limits
* soft nofile 1048576
* hard nofile 1048576

# Increase process limits
* soft nproc 1048576
* hard nproc 1048576

# Increase memory lock limits (for GPU if available)
* soft memlock unlimited
* hard memlock unlimited

# Increase stack size
* soft stack 65536
* hard stack 65536
EOF

echo "✓ System limits configured"

# Optimize Docker daemon if installed
if command -v docker &> /dev/null; then
    mkdir -p /etc/docker
    
    cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 1048576,
      "Soft": 1048576
    },
    "nproc": {
      "Name": "nproc",
      "Hard": 1048576,
      "Soft": 1048576
    }
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10
}
EOF
    
    echo "✓ Docker daemon optimized"
    
    # Restart Docker to apply changes
    systemctl restart docker 2>/dev/null || snap restart docker 2>/dev/null || true
    echo "✓ Docker restarted"
fi

# Disable transparent huge pages (can cause latency issues)
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Make it persistent
cat > /etc/systemd/system/disable-thp.service <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
EOF

systemctl daemon-reload
systemctl enable disable-thp.service
systemctl start disable-thp.service

echo "✓ Transparent huge pages disabled"

# Optimize I/O scheduler for SSDs (AWS uses SSDs)
for disk in /sys/block/nvme*; do
    if [ -d "$disk" ]; then
        echo none > $disk/queue/scheduler 2>/dev/null || true
        echo "✓ I/O scheduler optimized for $(basename $disk)"
    fi
done

echo ""
echo "=========================================="
echo "Kernel Tuning Complete!"
echo "=========================================="
echo ""
echo "Applied optimizations:"
echo "  ✓ Memory management (reduced swappiness, increased map count)"
echo "  ✓ Network buffers (increased for better throughput)"
echo "  ✓ File descriptors (increased limits)"
echo "  ✓ Shared memory (increased for AI models)"
echo "  ✓ Docker optimizations (if installed)"
echo "  ✓ I/O scheduler (optimized for SSDs)"
echo "  ✓ Transparent huge pages (disabled)"
echo ""
echo "Current key settings:"
echo "  vm.swappiness = $(sysctl -n vm.swappiness)"
echo "  vm.max_map_count = $(sysctl -n vm.max_map_count)"
echo "  fs.file-max = $(sysctl -n fs.file-max)"
echo "  net.core.somaxconn = $(sysctl -n net.core.somaxconn)"
echo ""
echo "Note: Some settings require a reboot to take full effect"
echo "=========================================="
