# socks5

Script tự động cài đặt Dante SOCKS5 Proxy trên máy chủ (Google Cloud / VPS).

## Tính năng

- Cài đặt Dante SOCKS5
- Tạo username/password ngẫu nhiên
- Random port trong khoảng 20000–30000
- Hiển thị proxy ngay sau khi cài
- Lưu thông tin proxy vào:
  - `/root/proxy-credentials.txt`
  - `/root/proxy-connection.txt` (dạng IP:PORT:USER:PASS)

## Hướng dẫn sử dụng

```bash
wget https://raw.githubusercontent.com/Phamgioi993/socks5/main/install.sh
chmod +x install.sh
./install.sh
