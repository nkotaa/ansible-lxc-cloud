#!/usr/bin/sh
#
# Seed NoCloud runtime configurations

# Script only runs on cloud-init boot
if [ -z "$NOCLOUD_INSTANCE_ID" ]; then
        exit 0
fi

NOCLOUD_SEEDFROM_SCHEME=${NOCLOUD_SEEDFROM%%://*}

if [ "$NOCLOUD_SEEDFROM_SCHEME" != "file" ]; then
        exit 1
fi

NOCLOUD_SEEDFROM_PATH=${NOCLOUD_SEEDFROM#*//}
HOST_PATH="$LXC_ROOTFS_MOUNT/$NOCLOUD_SEEDFROM_PATH"

mkdir -p "$HOST_PATH"

echo "$NOCLOUD_USER_DATA_B64" | base64 --decode - > "$HOST_PATH/user-data"
echo "$NOCLOUD_VENDOR_DATA_B64" | base64 --decode - > "$HOST_PATH/vendor-data"
cat << EOF > "$HOST_PATH/meta-data"
instance-id: $NOCLOUD_INSTANCE_ID
local_hostname: $LXC_NAME
EOF
