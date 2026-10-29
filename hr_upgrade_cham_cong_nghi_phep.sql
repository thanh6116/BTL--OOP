-- =====================================================================
-- NÂNG CẤP: thêm Chấm công + Nghỉ phép cho CSDL hrdb đã có sẵn
-- Chỉ cần chạy file này nếu bạn ĐÃ import hr_system.sql bản cũ (chưa có 2 bảng này).
-- Nếu import mới hoàn toàn thì hr_system.sql đã bao gồm sẵn, không cần chạy file này.
-- =====================================================================
USE hrdb;

-- Chấm công: mỗi nhân viên tối đa 1 dòng / ngày
--   PRESENT: đúng giờ | LATE: đi muộn | ABSENT: vắng mặt | LEAVE: nghỉ phép (tự tạo khi đơn được duyệt)
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id     INT AUTO_INCREMENT PRIMARY KEY,
    employee_id       INT NOT NULL,
    work_date         DATE NOT NULL,
    check_in          TIME NULL,
    check_out         TIME NULL,
    attendance_status ENUM('PRESENT','LATE','ABSENT','LEAVE') NOT NULL,
    note              VARCHAR(255),
    updated_by        VARCHAR(100),                    -- NULL = nhân viên tự chấm; có tên = admin chỉnh sửa
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_attendance_emp_date (employee_id, work_date),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- Đơn nghỉ phép
--   leave_type  : ANNUAL (phép năm) | SICK (nghỉ ốm) | UNPAID (không lương) | OTHER
--   leave_status: PENDING (chờ duyệt) | APPROVED | REJECTED | CANCELLED
CREATE TABLE IF NOT EXISTS leave_requests (
    leave_id     INT AUTO_INCREMENT PRIMARY KEY,
    employee_id  INT NOT NULL,
    leave_type   ENUM('ANNUAL','SICK','UNPAID','OTHER') NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    total_days   INT NOT NULL,                         -- số ngày làm việc (T2-T6) trong khoảng nghỉ
    reason       VARCHAR(255) NOT NULL,
    leave_status ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    reviewed_by  VARCHAR(100),
    review_note  VARCHAR(255),
    reviewed_at  TIMESTAMP NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    INDEX idx_leave_status (leave_status)
);
