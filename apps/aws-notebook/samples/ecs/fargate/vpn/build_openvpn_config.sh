#!/bin/bash

set -e

eval "$(jq -r '@sh "VPN_DNS=\(.vpn_server_dns)"')"

# The VPN_DNS we get from terraform will have the prefix '*.', so we trim it. 
# Ref: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html#:~:text=Locate%20the%20line%20that%20specifies%20the%20Client%20VPN%20endpoint%20DNS%20name,asdfa.cvpn%2Dendpoint%2D0102bc4c2eEXAMPLE.prod.clientvpn.us%2Dwest%2D2.amazonaws.com
cat > ./generated/vpn_client_config.ovpn << EOF
client
dev tun
proto udp
remote random.${VPN_DNS:2:${#VPN_DNS}} 443
remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3
route-nopull
route 10.0.0.0 255.255.0.0
<ca>
$(cat ./generated/ca.crt)
</ca>

<cert>
$(cat ./generated/notebook.client.crafting.demo.crt)
</cert>

<key>
$(cat ./generated/notebook.client.crafting.demo.key)
</key>

reneg-sec 0
EOF


cat << EOF
{
  "client_config":"./generated/vpn_client_config.ovpn"
}
EOF
