-- load this before /usr/share/wireplumber/bluetooth.lua.d/90-enable-all.lua

-- do not start and stop bluez with login: always run
bluez_monitor.properties["with-logind"] = false