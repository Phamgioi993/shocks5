#!/bin/bash

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "⚠️ Vui lòng chạy script bằng quyền root: sudo ./install.sh"
   exit 1
fi

# Phát hiện interface mạng chính (dựa vào route ra internet)
IFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')
if [[ -z "$IFACE" ]]; then
  echo "❌ Không phát hiện được interface mạng. Thoát."
  exit 1
fi

# Cập nhật và cài đặt Dante SOCKS5
apt update -y && apt install -y dante-server curl

# Tạo username và password ngẫu nhiên
USERNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)"

# Tạo user không login
useradd -M -s /usr/sbin/nologin $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Random port proxy (trong khoảng 20000–30000)
PROXY_PORT=$(shuf -i 20000-30000 -n 1)

# Lấy IP công cộng của máy chủ
SERVER_IP=$(curl -s ifconfig.me)

# Tạo file cấu hình Dante với interface được phát hiện
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: $IFACE port = $PROXY_PORT
external: $IFACE
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

# Lưu thông tin proxy ra file
echo "SOCKS5 Proxy Credentials:" > /root/proxy-credentials.txt
echo "Username: $USERNAME" >> /root/proxy-credentials.txt
echo "Password: $PASSWORD" >> /root/proxy-credentials.txt
echo "Port: $PROXY_PORT" >> /root/proxy-credentials.txt
echo "IP: $SERVER_IP" >> /root/proxy-credentials.txt
echo "$SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD" > /root/proxy-connection.txt

# Mở firewall trên GCP nếu có gcloud CLI
if command -v gcloud &> /dev/null; then
    gcloud compute firewall-rules create socks5-proxy-$PROXY_PORT --allow tcp:$PROXY_PORT --target-tags=socks-proxy
fi

# Khởi động dịch vụ Dante
systemctl restart danted
systemctl enable danted

# In thông tin ra terminal
echo ""
echo "✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo "➡️ Proxy: $SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD"
echo "📁 Đã lưu vào /root/proxy-credentials.txt và /root/proxy-connection.txt"
