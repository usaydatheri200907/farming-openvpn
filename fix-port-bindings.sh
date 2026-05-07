#!/bin/bash

HOST_IP=$(curl -4 -s ifconfig.me)
START_PORT=1194

echo "->[INFO] Removing old proxy devices"

for c in $(lxc list -c n --format csv | grep ovpn); do
    echo "Processing $c"

    # Remove all vpn* devices
    for dev in $(lxc config device list "$c" | grep '^vpn'); do
        echo "  Removing $dev"
        lxc config device remove "$c" "$dev"
    done
done

echo
echo "->[INFO] Recreating proxy devices"

i=0
for c in $(lxc list -c n --format csv | grep ovpn); do
    container_ip=$(lxc exec "$c" -- sh -c \
        "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")

    listen_port=$((START_PORT + i))
    device_name="vpn$listen_port"

    echo "Adding proxy for $c --> $container_ip:1194 (listen $HOST_IP:$listen_port)"

    lxc config device add "$c" "$device_name" proxy \
        listen=udp:$HOST_IP:$listen_port \
        connect=udp:$container_ip:1194

    i=$((i+1))
done

echo
echo "->[INFO] Done"
