#!/bin/bash

# Cập nhật và cài đặt Dante SOCKS5
apt update -y && apt upgrade -y
apt install -y dante-server curl

# Tạo username và password ngẫu nhiên
USERNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)"

# Tạo user không login
useradd -M -s /usr/sbin/nologin $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Random port proxy (trong khoảng an toàn)
PROXY_PORT=$(shuf -i 20000-30000 -n 1)

# Lấy IP công cộng của máy chủ
SERVER_IP=$(curl -s ifconfig.me)

# Tạo file cấu hình Dante
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: eth0 port = $PROXY_PORT
external: eth0
method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    method: username
    log: connect disconnect error
}
EOF

# Ghi thông tin vào file
echo "SOCKS5 Proxy Credentials:" > /root/proxy-credentials.txt
echo "Username: $USERNAME" >> /root/proxy-credentials.txt
echo "Password: $PASSWORD" >> /root/proxy-credentials.txt
echo "Port: $PROXY_PORT" >> /root/proxy-credentials.txt
echo "IP: $SERVER_IP" >> /root/proxy-credentials.txt

# Ghi dạng ip:port:user:pass riêng để dễ grep
echo "$SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD" > /root/proxy-connection.txt

# Tự động mở port nếu dùng GCP CLI
if command -v gcloud &> /dev/null; then
    gcloud compute firewall-rules create socks5-proxy-$PROXY_PORT --allow tcp:$PROXY_PORT --target-tags=socks-proxy
fi

# Khởi động dịch vụ Dante
systemctl restart danted
systemctl enable danted

# In thông tin ra màn hình
echo ""
echo "✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo "➡️ Proxy: $SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD"
echo "📁 Đã lưu vào /root/proxy-credentials.txt và /root/proxy-connection.txt"
