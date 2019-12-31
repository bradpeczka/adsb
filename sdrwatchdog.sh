#!/bin/bash
#
# sdrwatchdog.sh
# Looks for syslog message saying that the RTLSDR dongle has wedged, restarts dump1090-fa if needed, and sends an alert via Pushover
#
# With credit and thanks to:
# https://discussions.flightaware.com/t/dump1090-fa-stops-sending-messages-after-some-time/41789/11
# https://gist.github.com/outadoc/848c74677b93dbe2e8f4

pushmail() {
    APP_TOKEN='x'
    USER_TOKEN='x'
    TITLE="$1"
    MESSAGE="$2"
    curl 'https://api.pushover.net/1/messages.json' -X POST -d "token=$APP_TOKEN&user=$USER_TOKEN&message=$MESSAGE&title=$TITLE\""
}

exec &>>/tmp/wedge
sleep 20

journalctl -b -0 -f -n0 | grep 'No data received from the SDR for a long time' --line-buffered | {
        while read line
        do
                date
                systemctl kill -s 9 dump1090-fa
                if [ $? -eq 0 ]; then
                        sleep .3
                        systemctl restart dump1090-fa
                        if [ $? -eq 0 ]; then
                                logger "dump1090-fa was successfully restarted by watchdog"
                                pushmail Piaware RTLSDR dongle has wedged, and the watchdog successfully restarted dump1090-fa.
                        else
                                logger "dump1090-fa failed to restart by watchdog"
                                pushmail Piaware RTLSDR dongle has wedged, and the watchdog could not restart dump1090-fa. Please investigate!
                        fi
                else
                        logger "dump1090-fa is borked, we're going to restart the box"
                        pushmail Piaware RTLSDR dongle has wedged, and dump1090-fa has hung. We're going to restart the Pi.
                        shutdown -r now
                fi
        done
}
