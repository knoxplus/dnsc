# DNS Changer

A modern Flutter desktop and mobile application to natively manage and switch Domain Name System (DNS) servers on Windows, Linux, and Android.

## Features
- VPN-like switch to quickly apply predefined or custom DNS lists
- Support for multiple built-in DNS like Google and Cloudflare
- Add your own custom DNS records
- Explore publicly available DNS from a fetched JSON
- Check latency manually using the ping button
- Flush system DNS caches locally

## Setup Instructions
Since the platform folders (like `windows/` and `android/`) are not included yet, please run the following command in your terminal once you install Flutter to generate them:

```bash
flutter create .
```

Afterward, install the dependencies and run the application:
```bash
flutter pub get
flutter run -d windows
```

> **Note**: Modifying Windows DNS using `netsh` queries inside the app may require you to run the application with **Administrator privileges**.
