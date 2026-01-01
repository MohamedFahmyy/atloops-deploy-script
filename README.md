# 🚀 AT LOOPS Secure Deployment Script

![Bash](https://img.shields.io/badge/Bash-Script-green?logo=gnu-bash)
![Ubuntu](https://img.shields.io/badge/Tested-Ubuntu%2020.04%20%7C%2022.04-blue)
![License](https://img.shields.io/github/license/MohamedFahmyy/atloops-deploy-script)
![Stars](https://img.shields.io/github/stars/MohamedFahmyy/atloops-deploy-script?style=social)
![Forks](https://img.shields.io/github/forks/MohamedFahmyy/atloops-deploy-script?style=social)

One-command **secure production deployment** script for modern web applications on Ubuntu servers.

Built for freelancers, startups, and developers who want **fast, repeatable, and secure deployments**.

---

## 🔥 Features

- Automated Apache, PHP, and MySQL installation
- Secured phpMyAdmin with Basic Authentication
- Free SSL certificates via Let’s Encrypt (Certbot)
- Automatic HTTP → HTTPS redirection
- Firewall enabled (UFW)
- Supports multiple technologies:
  - Laravel
  - PHP
  - Node.js APIs
  - Vue.js
  - React
- Production-ready permissions and optimizations

---

## 🛠 Requirements

- Ubuntu 20.04 or 22.04
- Root or sudo privileges
- Domain name pointed to the server IP

---

## 🚀 Usage

```bash
sed -i 's/\r$//' deploy-secure.sh
chmod +x deploy-secure.sh
sudo ./deploy-secure.sh
