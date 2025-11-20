#!/bin/bash

# Konfigurasi awal
declare -A users
users=(
  [root]=cello
  [admin]=admin123
)

PORTS=(1080)

echo "[INFO] Update & install dependensi..."
apt update -y
apt install squid apache2-utils -y

echo "[INFO] Membuat file kredensial..."
rm -f /etc/squid/passwd
touch /etc/squid/passwd

for user in "${!users[@]}"; do
  htpasswd -b /etc/squid/passwd "$user" "${users[$user]}"
done

echo "[INFO] Backup konfigurasi lama..."
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

echo "[INFO] Menulis konfigurasi baru Squid..."
cat <<EOF > /etc/squid/squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm Squid Proxy Auth
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
EOF

for port in "${PORTS[@]}"; do
  echo "http_port $port" >> /etc/squid/squid.conf
done

cat <<EOF >> /etc/squid/squid.conf

# Izinkan semua IP (gunakan ACL IP jika ingin membatasi)
acl all src 0.0.0.0/0
http_access allow all

dns_nameservers 1.1.1.1 8.8.8.8
EOF

echo "[INFO] Restart service Squid..."
systemctl restart squid
systemctl enable squid

# Output hasil
IP=$(curl -s ipv4.icanhazip.com)
echo -e "\n✅ PROXY BERHASIL DIINSTAL:"
for port in "${PORTS[@]}"; do
  for user in "${!users[@]}"; do
    echo "$IP:$port:$user:${users[$user]}"
  done
done
