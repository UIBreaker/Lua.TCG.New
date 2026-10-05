APK đã ký được giữ tại đây để quy trình GitHub Actions phát hành mà không cần chuyển khóa ký lên GitHub. Người chơi nên tải APK trong Releases.

Đóng gói lại bằng `scripts/build_android.py`, dùng Java 17, APKTool 3.0.3, Android build-tools 35.0.0 và runtime chính thức `love-11.5-android-embed-norecording.apk` từ `love2d/love-android` tag `11.5a`. Gói game đầu vào được tạo bởi `scripts/build_release.py --target mobile`.

Sao lưu riêng thư mục `.android-signing/` trên máy phát hành, gồm khóa và mật khẩu. Không commit hoặc chia sẻ thư mục này. Các bản cập nhật phải dùng cùng khóa và tăng versionCode.

<!-- ponytail: lưu một APK 58 MiB trong Git để phát hành ngay; chuyển sang CI build với signing secrets nếu phát hành nhiều phiên bản để tránh tăng lịch sử Git. -->
