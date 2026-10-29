# Hệ thống Quản lý Nhân viên (Java Swing + MySQL)

## Cài đặt
1. Chạy `hr_system.sql` trong MySQL (tạo CSDL `hrdb` + dữ liệu mẫu).
   *Nếu bạn đã import bản cũ (chưa có chấm công/nghỉ phép)*: chạy thêm `hr_upgrade_cham_cong_nghi_phep.sql` để thêm 2 bảng mới, không mất dữ liệu.
2. Sao chép `db.properties.example` thành `db.properties` (cùng thư mục với `build.xml`), sửa user/password MySQL.
   (Hoặc dùng biến môi trường `HR_DB_URL`, `HR_DB_USER`, `HR_DB_PASSWORD`.)
3. Mở bằng NetBeans, thêm thư viện `mysql-connector-j` vào Libraries (đường dẫn cũ trỏ vào máy tác giả gốc).
4. Chạy `view.Main`.

Tài khoản mẫu: Admin `admin` / `Admin@123` (tick "Quản trị viên"); nhân viên `nv0001`…`nv0004` / `Nhanvien@123`.

## Bảng đối chiếu Ngân hàng → Nhân sự
| Bản ngân hàng | Bản nhân sự |
|---|---|
| Customer (khách hàng) | Employee (nhân viên: mã NV, phòng ban, chức vụ, lương, ngày vào làm, trạng thái) |
| Account (tài khoản, số dư, PIN) | Department (phòng ban) + lương cơ bản nằm trong Employee |
| Transaction (nạp/rút/chuyển) | SalaryRecord (khởi điểm / tăng / giảm / thưởng / điều chuyển) |
| Khóa / mở khóa tài khoản | Trạng thái: Đang làm việc / Nghỉ phép / Đã nghỉ việc |
| Admin | Admin (giữ nguyên) |
| Register (tự đăng ký) | ThemNhanVien (Admin tạo tài khoản nhân viên) |
| Menu_KH, TaiKhoanKhachHang, BienLaiGiaoDich, NapTien/RutTien/ChuyenTien | Menu_NV, HoSoNhanVien, LichSuLuong (3 màn nạp/rút/chuyển bị bỏ) |
| DanhSachKhachHang, QuanLyKhachHang, BaoCaoThongKe | DanhSachNhanVien, QuanLyNhanVien, BaoCaoThongKe; thêm QuanLyPhongBan |
| (mới) | Chấm công: `ChamCongNhanVien`, `QuanLyChamCong` (bảng `attendance`) |
| (mới) | Nghỉ phép: `NghiPhepNhanVien`, `DuyetNghiPhep` (bảng `leave_requests`) |

## Chức năng
- **Nhân viên**: xem hồ sơ, xem lịch sử lương, sửa thông tin cá nhân, đổi mật khẩu, quên mật khẩu (CCCD + SĐT).
- **Admin**: thêm / tìm / sửa nhân viên, cho nghỉ việc / khôi phục hàng loạt, tăng-giảm lương và thưởng (có lịch sử),
  điều chuyển phòng ban / chức vụ (tự ghi lịch sử), đặt lại mật khẩu, quản lý phòng ban, báo cáo theo phòng ban.

### Chấm công
- Nhân viên bấm **Check-in / Check-out** (mỗi ngày 1 lần mỗi loại), xem lịch sử và thống kê theo tháng.
- Check-in sau **08:30** tính **đi muộn** (hằng số `AttendanceService.ON_TIME_UNTIL`). Giờ lấy theo đồng hồ máy chạy ứng dụng.
- Admin xem chấm công **theo ngày** (cả nhân viên chưa chấm), **chỉnh sửa thủ công** (quên chấm, sửa giờ, ghi nhận vắng mặt),
  và xem **tổng hợp theo tháng**. Chỉ nhân viên trạng thái "Đang làm việc" mới chấm công được.
- "Vắng" chỉ là ngày admin đã ghi nhận; ngày không có bản ghi **không** tự tính là vắng.

### Nghỉ phép
- Nhân viên tạo đơn (phép năm / nghỉ ốm / không lương / khác), xem số dư phép, hủy đơn.
- Quỹ **phép năm 12 ngày/năm** (`LeaveService.ANNUAL_QUOTA`), tính cả đơn đang chờ duyệt; ngày nghỉ chỉ đếm **Thứ 2-Thứ 6**.
- Không cho xin nghỉ ở quá khứ (riêng nghỉ ốm được xin bù lùi tối đa 7 ngày); không cho trùng đơn khác.
- Admin **duyệt / từ chối** (từ chối bắt buộc nhập lý do). Khi duyệt, hệ thống tự ghi trạng thái "Nghỉ phép" vào bảng chấm công
  cho từng ngày làm việc trong khoảng nghỉ (cùng một transaction). Hủy đơn đã duyệt (chưa tới ngày nghỉ) sẽ gỡ các dòng đó.
- Dashboard thống kê có thêm: số người có mặt hôm nay, đang nghỉ phép hôm nay, đơn chờ duyệt.

## Thay đổi so với bản gốc (ngoài việc đổi nghiệp vụ)
- Mật khẩu được băm PBKDF2 (`util/PasswordUtil`) thay vì lưu thô.
- Mật khẩu CSDL không còn ghi cứng trong mã nguồn (đọc từ `db.properties` / biến môi trường).
- Chưa xử lý ngày lễ, chưa tính chấm công vào bảng lương (hai phần này độc lập với nhau).
- Ngày tháng dùng `LocalDate` thay vì chuỗi; cập nhật lương + ghi lịch sử nằm trong cùng một transaction.
