\# AN\_REPO\_CHANGELOG.md



\## Nhánh: An\_Repo



File này ghi lại các thay đổi chính trong nhánh `An\_Repo` để thành viên khác trong nhóm có thể clone, cài đặt và chạy project SaiGonTravid đúng cách.



\---



\## 1. Các chức năng đã bổ sung/chỉnh sửa



\### 1.1. Auth / Tài khoản



\* Bổ sung API đăng ký, đăng nhập, quên mật khẩu.

\* Quên mật khẩu gửi mật khẩu tạm thời về Gmail thông qua SMTP.

\* Không gửi lại mật khẩu cũ, chỉ gửi mật khẩu tạm.

\* Bổ sung đăng nhập Google bằng `google\_sign\_in`.

\* Bổ sung màn tài khoản.

\* Bổ sung màn chỉnh sửa thông tin tài khoản:



&#x20; \* Cập nhật họ tên.

&#x20; \* Cập nhật email.

&#x20; \* Cập nhật avatar từ thư viện ảnh.

\* Avatar được upload lên backend và lưu trong thư mục static.



\### 1.2. Review / Đánh giá



\* Bổ sung viết đánh giá địa điểm.

\* Bỏ phần tiêu đề đánh giá, chỉ giữ nội dung comment.

\* Cho phép chọn ảnh từ thư viện khi viết đánh giá.

\* Upload ảnh review lên backend.

\* Hiển thị ảnh review trong danh sách comment.

\* Bấm vào ảnh review để xem ảnh phóng lớn toàn màn hình.

\* Chặn người dùng đánh giá trùng một địa điểm:



&#x20; \* Nếu user đã đánh giá địa điểm đó thì nút “Viết đánh giá” sẽ bị vô hiệu hóa.

&#x20; \* Backend cũng chặn tạo review trùng.

\* Bổ sung chức năng xóa đánh giá của chính user:



&#x20; \* Xóa từ tab Đánh giá.

&#x20; \* Xóa từ phần comment trong chi tiết địa điểm.

&#x20; \* Không cho xóa review của user khác.



\### 1.3. Favorites / Địa điểm yêu thích



\* Bổ sung màn danh sách địa điểm yêu thích.

\* Từ tab Tài khoản, bấm “Địa điểm yêu thích của tôi” sẽ mở danh sách yêu thích.

\* Sửa lỗi danh sách yêu thích bị dùng chung giữa nhiều tài khoản.

\* Favorite hiện được lưu theo từng user bằng SharedPreferences key riêng:



&#x20; \* `favorite\_places\_user\_<user\_id>`

\* Khi logout, UI favorite được clear khỏi memory nhưng không xóa dữ liệu favorite đã lưu của user.



\### 1.4. Recent / Đã xem gần đây



\* Tự động lưu địa điểm đã xem gần đây.

\* Tab Đánh giá có section “Đã xem gần đây”.

\* Bấm vào địa điểm đã xem gần đây sẽ mở màn chi tiết địa điểm.



\### 1.5. Database config



\* Giữ cấu hình database theo hướng tương thích nhóm:



&#x20; \* Fallback mặc định trong code: `Travel\_app`

&#x20; \* Máy cá nhân có thể override bằng biến môi trường `DATABASE\_URL` trong `backend/.env`

\* Không push file `.env` thật lên Git.



\---



\## 2. Các file môi trường cần tự tạo



Sau khi clone nhánh này, cần tạo file:



```txt

backend/.env

```



Nội dung mẫu:



```env

DATABASE\_URL=postgresql://postgres:Yeuuyen1234%40@localhost:5432/Travel\_app

SMTP\_EMAIL=your\_demo\_gmail@gmail.com

SMTP\_APP\_PASSWORD=your\_16\_character\_app\_password

```



Lưu ý:



\* Nếu database local tên là `travel\_app` thì đổi dòng `DATABASE\_URL` thành:



```env

DATABASE\_URL=postgresql://postgres:Yeuuyen1234%40@localhost:5432/travel\_app

```



\* Còn tên là `Travel\_app` thì giữ:



```env

DATABASE\_URL=postgresql://postgres:Yeuuyen1234%40@localhost:5432/Travel\_app

```



\* File `backend/.env` không được push lên Git vì có App Password Gmail.



\---



\## 3. Yêu cầu database



Project đang dùng PostgreSQL.



Cần có database chứa schema:



```txt

TravelApp

```



Các bảng chính cần có:



```txt

users

places

reviews

review\_images

categories

place\_images

districts

saved\_places

review\_likes

review\_replies

```



Lưu ý phân biệt:



```txt

Database: Travel\_app hoặc travel\_app tùy máy

Schema: TravelApp

```



Nếu đổi tên database mà không copy dữ liệu, app sẽ không load được data.



\---





\## 4. Cấu hình IP backend cho Flutter



Mở file:



```txt

travel\_app/lib/core/constants.dart

```

Kiểm tra IP:



```dart

static const String ip = "<<IP wifi máy>>";

static const String baseUrl = "http://$ip:8000/api";

```

\---



\## 5. Cấu hình Gmail SMTP cho quên mật khẩu



Để chức năng quên mật khẩu gửi Gmail hoạt động, cần:



1\. Xài Gmail clone.

2\. Bật xác minh 2 bước.

3\. Tạo App Password.

4\. Điền vào `backend/.env`:



```env

SMTP\_EMAIL=your\_demo\_gmail@gmail.com

SMTP\_APP\_PASSWORD=your\_16\_character\_app\_password

```





\---



\## 6. Cấu hình Google Login



Google Login cần cấu hình OAuth trên Google Cloud Console:



\* Android OAuth Client:



&#x20; \* Package name: `com.example.travel\_app`

&#x20; \* SHA-1 debug của máy build.

\* Web OAuth Client:



&#x20; \* Dùng làm `serverClientId` trong Flutter.



Nếu Google login lỗi:



```txt

ApiException: 10

```



thì cần kiểm tra lại:



\* SHA-1 debug.

\* Package name.

\* Web OAuth Client ID.

\* Test users trong OAuth consent screen.



\---



\## 7. Checklist test nhanh sau khi clone



Sau khi clone nhánh `An\_Repo`, test theo thứ tự:



1\. Backend `/api` chạy được.

2\. Home load danh sách địa điểm.

3\. Mở chi tiết địa điểm.

4\. Đăng ký tài khoản.

5\. Đăng nhập.

6\. Quên mật khẩu gửi Gmail.

7\. Đổi avatar và thông tin cá nhân.

8\. Viết đánh giá.

9\. Upload ảnh review.

10\. Bấm ảnh review để phóng lớn.

11\. Xóa review của chính mình.

12\. Kiểm tra không thể review trùng một địa điểm.

13\. Tim địa điểm yêu thích.

14\. Logout, login tài khoản khác, kiểm tra favorite không bị lẫn.

15\. Mở danh sách địa điểm yêu thích từ tab Tài khoản.



\---



\## 8. Lưu ý khi merge



Không push các file sau:



```txt

backend/.env

backend/.venv/

````

\---



\## 9. Lệnh chạy nhanh



Backend:

```powershell

cd "E:\\Lap\_trinh\_di\_dong\\CProject\\coding\\SaiGonTravid\\backend"

.\\.venv\\Scripts\\activate

uvicorn main:app --reload --host 0.0.0.0 --port 8000

```



Flutter:

```powershell

cd "E:\\Lap\_trinh\_di\_dong\\CProject\\coding\\SaiGonTravid\\travel\_app"

flutter pub get

flutter run

```



