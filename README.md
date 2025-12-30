# Antiscan is a simple tool for detecting and blocking IP addresses with suspicious activity.

## Antiscan is designed for Keenetic/Netcraze devices that support Entware.

### Features:
1) Blocking hosts that open multiple connections from a single IP address.
2) Blocking hosts that open single connections from multiple IP addresses belonging to the same /24 subnet.
3) Blocking hosts based on a user-defined blacklist/whitelist.
4) Geoblocking in blacklist/whitelist mode.
5) Blocking hosts using a honeypot.

> [!IMPORTANT]
> Antiscan is IPv4-only and only works for the TCP protocol.

### A detailed description of Antiscan's capabilities, as well as a discussion of its operation, can be found on the Keenetic Community forum: https://forum.keenetic.ru/topic/21009-antiscan/


### Requirements for the script to work correctly:
1. The installed component “Kernel modules for the Netfilter subsystem” (available without “IPv6 protocol” starting with software version 4.3).

### Installation:
1. Execute the command `opkg update && opkg install curl && curl -fsSL https://raw.githubusercontent.com/dimon27254/antiscan/refs/heads/main/install.sh | sh`
2. Specify the Unix names of Internet connection interfaces in the file `“/opt/etc/antiscan/ascn.conf”`. In software version 4.3 and above, Unix interface names can be viewed using the command `show interface {interface} system-name`.
3. Configure the remaining parameters to suit your needs, if necessary, in the file `“/opt/etc/antiscan/ascn.conf”`.
4. Start Antiscan with the command `antiscan start`

**For Antiscan versions 1.4 and above, configuration is available using [web4static](https://github.com/spatiumstas/web4static) from [spatiumstas](https://github.com/spatiumstas).**

### Description of parameters in ascn.conf:
```
# List of interfaces on which Antiscan operates. Multiple interfaces are specified by a space, for example: “eth3 eth2.2 ppp0”:
ISP_INTERFACES="eth3" 

# List of device service ports on which Antiscan operates. Multiple ports are separated by commas, for example: “22,80,443”:
PORTS="22,80,443"

# A list of host ports on the local network to which traffic is redirected. Example of entering multiple ports: “22,80,443”.
# PLEASE NOTE! Specify the ports from the “forward to port” field in the forwarding rules, not “open port.”
PORTS_FORWARDED="22,80,443"

# Use host blocking with “traps”. 0 - disabled, 1 - enabled
ENABLE_HONEYPOT=0
# A list of trap ports on which incoming connections are monitored. Example of entering multiple ports: “22,80,443”.
HONEYPOT_PORTS=""

# Duration of IP blocking by trap in seconds:   
HONEYPOT_BANTIME=864000

# Use host blocking based on accumulated IP/subnets. 0 - disabled, 1 - enabled
ENABLE_IPS_BAN=1
# Multiple connection limit settings:
# FOR EXPERIENCED USERS! Iptables rule mask for connection tracking:
RULES_MASK="255.255.255.255"

# Time to observe new connections with IP in seconds:
RECENT_CONNECTIONS_TIME=30 

# The threshold value for new connections during the RECENT_CONNECTIONS_TIME period, after which the IP will be blocked:
RECENT_CONNECTIONS_HITCOUNT=15    

# The total limit for multiple connections from a single address, after which it will be blocked:
RECENT_CONNECTIONS_LIMIT=20 

# Duration of IP blocking in seconds:     
RECENT_CONNECTIONS_BANTIME=864000   

# Settings for restricting connections from different IP addresses:
# Retention period for IP addresses that are candidates for blocking:
DIFFERENT_IP_CANDIDATES_STORAGETIME=864000

# The threshold value for IP candidates, starting from which a subnet will be created for blocking:
DIFFERENT_IP_THRESHOLD=5

# Subnet lock duration in seconds:
SUBNETS_BANTIME=864000

# The path to the directory that will contain all address lists. Example: “/tmp/mnt/MYDISK/antiscan”
IPSETS_DIRECTORY=""

# Save lists of accumulated blocked IPs and subnets to files. 0 - disabled, 1 - enabled
SAVE_IPSETS=0

# Save lists of accumulated blocked IPs and subnets when antiscan stop is called. 0 - disabled, 1 - enabled
SAVE_ON_EXIT=0

# Use custom list of exclusion addresses. 0 - disabled, 1 - enabled
USE_CUSTOM_EXCLUDE_LIST=0

# Blocking mode based on user lists. 0 - disabled, blacklist - blacklist, whitelist - whitelist
CUSTOM_LISTS_BLOCK_MODE=0

# Geo-blocking mode. 0 - disabled, blacklist - blacklist, whitelist - whitelist
GEOBLOCK_MODE=0

# List of countries for geo-blocking. Example: one country - “US”, multiple countries - “RU DE”
GEOBLOCK_COUNTRIES=""

# List of countries that are exceptions. Example: one country - “RU”, multiple countries - “RU DE”
GEO_EXCLUDE_COUNTRIES=""

# Reading system block lists by IP lockout policy. 0 - disabled, 1 - enabled
READ_NDM_LOCKOUT_IPSETS=0

# Retention period for records read from system lists:
LOCKOUT_IPSET_BANTIME=864000
```
> [!TIP]
> 1) The default reading time for the list of candidates is 1 minute.
> 
> Task text in **ascn_crontab.conf**: `*/1 * * * * /opt/etc/init.d/S99ascn read_candidates &`
>
> 2) The default period for reading system block lists is 2 minutes.
> 
> The text of the task in **ascn_crontab.conf**: `*/2 * * * * /opt/etc/init.d/S99ascn read_ndm_ipsets &`
>
> 3) Default address lists are saved every 5 days at 00:00.
>
> Text of the task in **ascn_crontab.conf**: `0 0 */5 * * /opt/etc/init.d/S99ascn save_ipsets &`
>
> 4) The default subnet lists for geo-blocking are updated every 15 days at 00:05.
>
> Task text in **ascn_crontab.conf**: `0 5 */15 * * /opt/etc/init.d/S99ascn update_ipsets geo &`

### Using Antiscan:
```
{start|stop|restart|status|list|reload|flush|version|edit|update_rules|read_candidates|read_ndm_ipsets|save_ipsets|update_ipsets|update_crontab}
start                            start the script (create rules, ipsets, start collecting IPs)
stop                             stop the script (delete rules, clear ipsets, unblock)
restart                          stop and restart the script
status                           display Antiscan status

list {ips|subnets|ndm_lockout|honeypot}   
                                 display a list and number of blocked IPs/subnets
								 
reload                           update the Antiscan configuration (reread the ascn.conf file)

flush [candidates|ips|subnets|custom_whitelist|custom_blacklist|custom_exclude|geo|ndm_lockout|honeypot]
                                 clear address lists and delete their files

version                          display the version of Antiscan installed

edit {config|crontab|custom_exclude|custom_blacklist|custom_whitelist}
                                 edit Antiscan configuration files or custom lists

update_rules                     Check for iptables rules and add them if they are missing (for the netfilter.d hook script)
read_candidates                  process a list of candidate addresses for blocking by subnet (run manually or on a schedule)
read_ndm_ipsets                  read system block lists by IP lockout policy (run manually or on a schedule)
save_ipsets                      save lists of accumulated addresses to files (run manually or on a schedule)
update_ipsets {custom|geo}       Update custom address lists or subnets for geoblocking (run manually or on a schedule)
update_crontab                   Update Antiscan tasks in the crontab file
```
