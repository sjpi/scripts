#
# Install-pg-with-streaming.sh

This installs postgres with streaming replication. Fill out the variables as needed. 

Trigger file (failover.trigger) will be used in recovery.conf to convert a standby to master. This is a MANUAL failover.


#
# setup-streaming-only.sh

This will only setup streaming replication on a currently active cluster. 
!! This has been only tested on a few setups !!

This file only uses the failover.trigger as a trigger file.