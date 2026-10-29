-- =====================================================================
-- HỆ THỐNG QUẢN LÝ NHÂN VIÊN (chuyển đổi từ hệ thống Ngân hàng)
-- Chạy file này trong MySQL Workbench / mysql CLI để tạo CSDL + dữ liệu mẫu
-- =====================================================================
CREATE DATABASE IF NOT EXISTS hrdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hrdb;

-- Phòng ban (thay cho "accounts" của bản ngân hàng: nơi nhân viên trực thuộc)
CREATE TABLE IF NOT EXISTS departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    description     VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Nhân viên (thay cho "customers")
CREATE TABLE IF NOT EXISTS employees (
    employee_id        INT AUTO_INCREMENT PRIMARY KEY,
    employee_code      VARCHAR(20) UNIQUE NOT NULL,
    username           VARCHAR(50) UNIQUE NOT NULL,
    password_hash      VARCHAR(255) NOT NULL,          -- PBKDF2: iterations:salt:hash
    citizen_id         VARCHAR(50) UNIQUE NOT NULL,
    full_name          VARCHAR(100) NOT NULL,
    date_of_birth      DATE,
    sex                ENUM('MALE','FEMALE','OTHER'),
    nationality        VARCHAR(255),
    place_of_origin    VARCHAR(255),
    place_of_residence VARCHAR(255),
    email              VARCHAR(100) UNIQUE,
    phone              VARCHAR(20),
    department_id      INT NULL,
    job_title          VARCHAR(100),
    base_salary        DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
    hire_date          DATE,
    employee_status    ENUM('ACTIVE','ON_LEAVE','RESIGNED') NOT NULL DEFAULT 'ACTIVE',
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
);

-- Lịch sử lương / điều chuyển (thay cho "transactions")
--   INITIAL  : lương khởi điểm      (≈ DEPOSIT  lần đầu)
--   RAISE    : tăng lương           (≈ DEPOSIT)
--   CUT      : giảm lương           (≈ WITHDRAW)
--   BONUS    : thưởng               (không đổi lương cơ bản)
--   TRANSFER : điều chuyển / bổ nhiệm (≈ TRANSFER)
CREATE TABLE IF NOT EXISTS salary_records (
    record_id      INT AUTO_INCREMENT PRIMARY KEY,
    employee_id    INT NOT NULL,
    record_type    ENUM('INITIAL','RAISE','CUT','BONUS','TRANSFER') NOT NULL,
    amount         DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
    record_content VARCHAR(255),
    created_by     VARCHAR(100),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

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

-- Quản trị viên nhân sự (giữ nguyên)
CREATE TABLE IF NOT EXISTS admins (
    admin_id   INT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(50) UNIQUE NOT NULL,
    password   VARCHAR(255) NOT NULL,                  -- PBKDF2: iterations:salt:hash
    full_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(100),
    role       VARCHAR(50) DEFAULT 'Quản trị viên',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================  DỮ LIỆU MẪU (xóa khi dùng thật)  =====================
-- Admin mẫu:      admin    / Admin@123
-- Nhân viên mẫu:  nv0001.. / Nhanvien@123
INSERT INTO admins (username, password, full_name, email, role) VALUES
('admin', '120000:a1b2c3d4e5f60718293a4b5c6d7e8f90:2dc49fb3c188e41775ea1e59c763a6beca771da60d41284217b303715d8b4551',
 'Quản trị viên', 'admin@company.vn', 'Trưởng phòng Nhân sự');

INSERT INTO departments (department_name, description) VALUES
('Ban Giám đốc', 'Điều hành chung'),
('Phòng Nhân sự', 'Tuyển dụng, đào tạo, chế độ'),
('Phòng Kế toán', 'Tài chính, kế toán, tiền lương'),
('Phòng Kỹ thuật', 'Phát triển và vận hành hệ thống'),
('Phòng Kinh doanh', 'Bán hàng và chăm sóc khách hàng');

INSERT INTO employees (employee_code, username, password_hash, citizen_id, full_name, date_of_birth, sex,
                       nationality, place_of_origin, place_of_residence, email, phone,
                       department_id, job_title, base_salary, hire_date) VALUES
('NV0001','nv0001','120000:0f1e2d3c4b5a69788796a5b4c3d2e1f0:f05b27b58a056fbecd6579fd1e2a8655645960bd1145e3234e1d42690b06c1d3',
 '001090000001','Nguyễn Văn An','1990-05-12','MALE','Việt Nam','Hà Nội','Cầu Giấy, Hà Nội','an.nv@company.vn','0901000001',
 2,'Chuyên viên nhân sự',15000000,'2020-03-01'),
('NV0002','nv0002','120000:0f1e2d3c4b5a69788796a5b4c3d2e1f0:f05b27b58a056fbecd6579fd1e2a8655645960bd1145e3234e1d42690b06c1d3',
 '001092000002','Trần Thị Bình','1992-11-03','FEMALE','Việt Nam','Nam Định','Thanh Xuân, Hà Nội','binh.tt@company.vn','0901000002',
 3,'Kế toán trưởng',22000000,'2019-07-15'),
('NV0003','nv0003','120000:0f1e2d3c4b5a69788796a5b4c3d2e1f0:f05b27b58a056fbecd6579fd1e2a8655645960bd1145e3234e1d42690b06c1d3',
 '001095000003','Lê Hoàng Cường','1995-01-27','MALE','Việt Nam','Hải Phòng','Đống Đa, Hà Nội','cuong.lh@company.vn','0901000003',
 4,'Lập trình viên',18000000,'2022-02-10'),
('NV0004','nv0004','120000:0f1e2d3c4b5a69788796a5b4c3d2e1f0:f05b27b58a056fbecd6579fd1e2a8655645960bd1145e3234e1d42690b06c1d3',
 '001098000004','Phạm Thu Dung','1998-08-19','FEMALE','Việt Nam','Thanh Hóa','Hà Đông, Hà Nội','dung.pt@company.vn','0901000004',
 5,'Nhân viên kinh doanh',12000000,'2023-09-05');

INSERT INTO salary_records (employee_id, record_type, amount, record_content, created_by) VALUES
(1,'INITIAL',15000000,'Lương khởi điểm','Quản trị viên'),
(2,'INITIAL',22000000,'Lương khởi điểm','Quản trị viên'),
(3,'INITIAL',18000000,'Lương khởi điểm','Quản trị viên'),
(4,'INITIAL',12000000,'Lương khởi điểm','Quản trị viên');
