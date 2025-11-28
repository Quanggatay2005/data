-- create database
drop database if exists BTL3;
create database BTL3;
use BTL3;


-- 1. bảng người dùng (cha)
create table USERS
(
    user_id         int primary key not null auto_increment,
    username        varchar(50)     not null unique,
    email           varchar(255)    not null unique,
    first_name      varchar(50)     not null,
    last_name       varchar(50)     not null,
    password        varchar(100)    not null,
    role            int             not null default 2, -- 0: admin, 1: instructor, 2: student
    bank_name       varchar(100),
    payment_account varchar(100),

    constraint chk_role check (role in (0, 1, 2)),
    constraint chk_email_format check ( email like '%@%' )
);

-- 2. bảng sinh viên (kế thừa users)
create table STUDENTS
(
    student_id      int primary key not null, -- dùng chung id với users
    enrollment_date date            not null default (current_date),

    foreign key (student_id) references USERS (user_id) on delete cascade
);

-- 3. bảng giảng viên (kế thừa users)
create table INSTRUCTORS
(
    instructor_id  int primary key not null, -- dùng chung id với users
    teaching_field varchar(255)    not null,
    bio            text,

    foreign key (instructor_id) references USERS (user_id) on delete cascade
);

-- 4. bảng admin (kế thừa users)
create table ADMINS
(
    admin_id int primary key not null, -- dùng chung id với users

    foreign key (admin_id) references USERS (user_id) on delete cascade
);

-- 5. bảng chủ đề
create table TOPICS
(
    topic_id    int primary key not null auto_increment,
    topic_name  varchar(100)    not null unique,
    description text
);

-- 6. bảng khóa học
create table COURSES
(
    course_id      int primary key not null auto_increment,
    course_name    varchar(255)    not null unique,
    description    text,
    language       varchar(50)     not null,
    price          decimal(10, 2)  not null default 0.00,
    min_score      int             not null default 50, -- điểm tối thiểu để đậu khóa học
    level          int             not null default 0,  -- 0: beginner, 1: intermediate, 2: advanced
    total_lectures int                      default 0,  -- thuộc tính dẫn xuất
    total_tests    int                      default 0,  -- thuộc tính dẫn xuất
    total_duration int                      default 0,  -- thuộc tính dẫn xuất

    constraint chk_course_price check ( price >= 0 ),
    constraint chk_min_score check ( min_score between 0 and 100),
    constraint chk_course_level check ( level in (0, 1, 2) )
);

-- 7. bảng liên kết khóa học - chủ đề (n-n)
create table COURSE_TOPICS
(
    course_id int not null,
    topic_id  int not null,

    primary key (course_id, topic_id),
    foreign key (course_id) references COURSES (course_id) on delete cascade,
    foreign key (topic_id) references TOPICS (topic_id) on delete cascade
);

-- 8. bảng chương (section)
create table SECTIONS
(
    section_id     int primary key not null auto_increment,
    course_id      int             not null,
    section_name   varchar(255)    not null,
    section_order  int             not null, -- thứ tự chương trong khóa
    total_lectures int default 0,
    total_tests    int default 0,

    foreign key (course_id) references COURSES (course_id) on delete cascade,
    unique key (course_id, section_order)
);

-- 9. bảng bài giảng (lecture)
create table LECTURES
(
    lecture_id         int primary key not null auto_increment,
    section_id         int             not null,
    lecture_name       varchar(255)    not null,
    link               varchar(500)    not null,
    attached_materials varchar(500),
    duration_minutes   int,
    status             int default 0, -- 0: notstarted, 1: inprogress, 2: completed (trạng thái mặc định)

    foreign key (section_id) references SECTIONS (section_id) on delete cascade,
    constraint chk_duration check ( duration_minutes is null or duration_minutes > 0 )
);

-- 10. bảng đề kiểm tra (test)
-- lưu ý: score ở đây là thang điểm của đề (ví dụ 100 điểm), không phải điểm sinh viên
create table TESTS
(
    test_id            int primary key not null auto_increment,
    section_id         int             not null,
    test_name          varchar(255)    not null,
    max_attempts       int             not null default 1,
    time_limit_minutes int             not null,
    test_url           varchar(500),
    score              int                      default 100, -- thang điểm tối đa của bài test

    foreign key (section_id) references SECTIONS (section_id) on delete cascade,
    constraint chk_max_attempts check ( max_attempts > 0 ),
    constraint chk_time_limit check ( time_limit_minutes > 0 )
);

-- 11. bảng câu hỏi (question) - thực thể yếu
create table QUESTIONS
(
    question_id    int primary key not null auto_increment,
    test_id        int             not null,
    content        text            not null,
    type           varchar(50)     not null,
    correct_answer text            not null,

    foreign key (test_id) references TESTS (test_id) on delete cascade,
    constraint chk_question_type check ( type in ('multiple_choice', 'true_false', 'short_answer', 'essay') )
);

-- 12. bảng lựa chọn sai (cho trắc nghiệm)
create table QUESTION_CHOICES
(
    choice_id    int primary key not null auto_increment,
    question_id  int             not null,
    wrong_choice text            not null,

    foreign key (question_id) references QUESTIONS (question_id) on delete cascade
);

-- 13. bảng kết quả làm bài (quan trọng: lưu điểm thực tế của sinh viên)
create table TEST_RESULTS
(
    result_id    int primary key not null auto_increment,
    student_id   int             not null,
    test_id      int             not null,
    actual_score decimal(5, 2) default 0, -- điểm sinh viên đạt được
    start_time   datetime        not null,
    submit_time  datetime,
    status       int           default 1, -- 1: inprogress, 2: completed

    foreign key (student_id) references STUDENTS (student_id) on delete cascade,
    foreign key (test_id) references TESTS (test_id) on delete cascade
);

-- 14. bảng giao dịch
create table TRANSACTIONS
(
    transaction_id   int primary key not null auto_increment,
    student_id       int             not null,
    course_id        int             not null,
    instructor_id    int             not null, -- giảng viên nhận tiền
    price            decimal(10, 2)  not null,
    payment_status   varchar(50)     not null,
    transaction_date datetime        not null default current_timestamp,

    foreign key (student_id) references STUDENTS (student_id) on delete restrict,
    foreign key (instructor_id) references INSTRUCTORS (instructor_id) on delete restrict,
    foreign key (course_id) references COURSES (course_id) on delete restrict,
    constraint chk_payment_status check ( payment_status in ('pending', 'completed', 'failed', 'refunded')),
    constraint chk_transaction_price check ( price > 0 )
);

-- 15. bảng chứng chỉ
create table CERTIFICATES
(
    certificate_id int primary key not null auto_increment,
    student_id     int             not null,
    course_id      int             not null,
    issued_date    date            not null default (current_date),

    foreign key (student_id) references STUDENTS (student_id) on delete restrict,
    foreign key (course_id) references COURSES (course_id) on delete restrict,
    unique key (student_id, course_id)
);

-- 16. bảng giảng viên phụ trách khóa học (n-n)
create table COURSE_INSTRUCTORS
(
    course_id          int not null,
    instructor_id      int not null,
    is_main_instructor boolean default false,

    primary key (course_id, instructor_id),
    foreign key (course_id) references COURSES (course_id) on delete cascade,
    foreign key (instructor_id) references INSTRUCTORS (instructor_id) on delete cascade
);

-- 17. bảng đăng ký học (n-n: students - courses)
create table ENROLLMENTS
(
    student_id        int  not null,
    course_id         int  not null,
    enrollment_date   date not null default (current_date),
    completion_status int  not null default 0, -- 0: in progress, 1: completed

    primary key (student_id, course_id),
    foreign key (student_id) references STUDENTS (student_id) on delete cascade,
    foreign key (course_id) references COURSES (course_id) on delete cascade
);

-- 18. bảng điều kiện tiên quyết (tự liên kết courses)
create table PREREQUISITES
(
    course_id              int not null,
    prerequisite_course_id int not null,

    primary key (course_id, prerequisite_course_id),
    foreign key (course_id) references COURSES (course_id) on delete cascade,
    foreign key (prerequisite_course_id) references COURSES (course_id) on delete cascade,

    constraint chk_no_self_prereq check (course_id <> prerequisite_course_id)
);

-- 19. bảng đánh giá khóa học
create table COURSE_RATINGS
(
    student_id  int      not null,
    course_id   int      not null,
    rating      int      not null,
    comment     text,
    rating_date datetime not null default current_timestamp,

    primary key (student_id, course_id),
    foreign key (student_id) references STUDENTS (student_id) on delete cascade,
    foreign key (course_id) references COURSES (course_id) on delete cascade,

    constraint chk_rating_value check (rating between 1 and 5)
);

-- 20. bảng theo dõi tiến độ xem bài giảng
create table LECTURE_VIEWS
(
    student_id int      not null,
    lecture_id int      not null,
    status     int      not null default 0, -- 0: notstarted, 1: inprogress, 2: completed
    view_date  datetime not null default current_timestamp,

    primary key (student_id, lecture_id),
    foreign key (student_id) references STUDENTS (student_id) on delete cascade,
    foreign key (lecture_id) references LECTURES (lecture_id) on delete cascade,

    constraint chk_view_status check (status in (0, 1, 2))
);

insert into USERS (user_id, username, email, first_name, last_name, password, role, bank_name, payment_account)
values (1, 'admin_hcmut', 'admin@hcmut.edu.vn', 'Quan', 'Tri Vien', '$2a$12$Hash...', 0, null, null),
-- instructors (ids 2-5)
       (2, 'gv_thanh', 'thanh.nguyen@hcmut.edu.vn', 'Thanh', 'Nguyen Van', '$2a$12$Hash...', 1, 'Vietcombank',
        '0071000123456'),
       (3, 'gv_huong', 'huong.le@hcmut.edu.vn', 'Huong', 'Le Thi', '$2a$12$Hash...', 1, 'TPBank', '000111222333'),
       (4, 'gv_tung', 'tung.hoang@hcmut.edu.vn', 'Tung', 'Hoang Viet', '$2a$12$Hash...', 1, 'Techcombank',
        '190333444555'),
       (5, 'gv_minh', 'minh.pham@hcmut.edu.vn', 'Minh', 'Pham Nhat', '$2a$12$Hash...', 1, 'MBBank', '999988887777'),
-- students (ids 6-15)
       (6, 'sv_an', 'an.nguyen123@hcmut.edu.vn', 'An', 'Nguyen Van', '$2a$12$Hash...', 2, 'Momo', '0909123456'),
       (7, 'sv_binh', 'binh.tran@hcmut.edu.vn', 'Binh', 'Tran Thi', '$2a$12$Hash...', 2, 'ViettelPay', '0987654321'),
       (8, 'sv_cuong', 'cuong.le@gmail.com', 'Cuong', 'Le Quoc', '$2a$12$Hash...', 2, 'ZaloPay', '0918123123'),
       (9, 'sv_dung', 'dung.pham@hcmut.edu.vn', 'Dung', 'Pham Tien', '$2a$12$Hash...', 2, 'VietinBank', '1010101010'),
       (10, 'sv_giang', 'giang.ho@gmail.com', 'Giang', 'Ho Huong', '$2a$12$Hash...', 2, 'Agribank', '220012341234'),
       (11, 'sv_hai', 'hai.vo@hcmut.edu.vn', 'Hai', 'Vo Thanh', '$2a$12$Hash...', 2, 'BIDV', '370012341234'),
       (12, 'sv_khanh', 'khanh.do@hcmut.edu.vn', 'Khanh', 'Do Duy', '$2a$12$Hash...', 2, 'ACB', '1010109999'),
       (13, 'sv_lan', 'lan.nguyen@gmail.com', 'Lan', 'Nguyen Ngoc', '$2a$12$Hash...', 2, 'Sacombank', '601100001111'),
       (14, 'sv_minh', 'minh.vu@hcmut.edu.vn', 'Minh', 'Vu Duc', '$2a$12$Hash...', 2, 'VIB', '411122223333'),
       (15, 'sv_nam', 'nam.buu@hcmut.edu.vn', 'Nam', 'Buu Hoang', '$2a$12$Hash...', 2, 'VPBank', '0908777666');

-- =============================================
-- 2. seed data: sub-tables (inheritance)
-- =============================================
insert into ADMINS (admin_id)
values (1),
       (2),
       (3),
       (4);

insert into INSTRUCTORS (instructor_id, teaching_field, bio)
values (2, 'Khoa Hoc May Tinh & AI', 'Tien si KHMT tu Phap, 10 nam kinh nghiem giang day Machine Learning.'),
       (3, 'Cong Nghe Phan Mem', 'Chuyen gia Fullstack Developer, tung lam viec tai FPT Software.'),
       (4, 'He Thong Thong Tin', 'Nghien cuu ve Big Data va Data Mining tai Vien CNTT.'),
       (5, 'Mang May Tinh & An Ninh Mang', 'Chung chi CISSP, CEH. Chuyen gia bao mat he thong.');

insert into STUDENTS (student_id, enrollment_date)
values (6, '2023-09-05'),
       (7, '2023-09-05'),
       (8, '2023-09-10'),
       (9, '2023-09-12'),
       (10, '2023-10-01'),
       (11, '2023-10-05'),
       (12, '2023-10-15'),
       (13, '2023-11-01'),
       (14, '2023-11-05'),
       (15, '2023-11-10');

-- =============================================
-- 3. seed data: TOPICS (6 rows)
-- =============================================
insert into TOPICS (topic_name, description)
values ('Lap Trinh Co Ban', 'Nen tang lap trinh C/C++, Python cho nguoi moi bat dau'),
       ('Phat Trien Web', 'Frontend, Backend, ReactJS, NodeJS, PHP'),
       ('Khoa Hoc Du Lieu', 'Phan tich du lieu, Machine Learning, Deep Learning'),
       ('Co So Du Lieu', 'Thiet ke CSDL, SQL Server, MySQL, MongoDB'),
       ('An Ninh Mang', 'Bao mat he thong, Pentest, Cryptography'),
       ('Ky Nang Mem', 'Quan ly thoi gian, thuyet trinh, lam viec nhom');

-- =============================================
-- 4. seed data: COURSES (8 rows)
-- lưu ý: giá tiền chuyển sang VND
-- =============================================
insert into COURSES (course_id, course_name, description, language, price, min_score, level, total_lectures,
                     total_tests, total_duration)
values (1, 'Nhap Mon Lap Trinh C++', 'Khoa hoc nen tang cho sinh vien nam nhat.', 'Tieng Viet', 500000.00, 50, 0, 0, 0,
        0),
       (2, 'Cau Truc Du Lieu & Giai Thuat', 'Nam vung cac thuat toan cot loi.', 'Tieng Viet', 800000.00, 50, 1, 0, 0,
        0),
       (3, 'Lap Trinh Web Fullstack voi React & Node', 'Xay dung website thuong mai dien tu.', 'Tieng Anh', 1200000.00,
        60, 2, 0, 0, 0),
       (4, 'He Quan Tri Co So Du Lieu', 'Thanh thao SQL va thiet ke Database.', 'Tieng Viet', 600000.00, 50, 1, 0, 0,
        0),
       (5, 'Python cho Phan Tich Du Lieu', 'Xu ly du lieu voi Pandas, NumPy.', 'Tieng Viet', 1000000.00, 60, 1, 0, 0,
        0),
       (6, 'Nhap Mon Tri Tue Nhan Tao', 'Co ban ve AI va Machine Learning.', 'Tieng Anh', 1500000.00, 70, 2, 0, 0, 0),
       (7, 'Mang May Tinh Co Ban', 'Kien thuc ve TCP/IP, OSI model.', 'Tieng Viet', 700000.00, 50, 0, 0, 0, 0),
       (8, 'Luyen Thi Chung Chi AWS Cloud', 'Kien thuc dien toan dam may AWS.', 'Tieng Anh', 2000000.00, 75, 2, 0, 0,
        0);

-- =============================================
-- 5. linking tables: COURSE_INSTRUCTORS & COURSE_TOPICS
-- =============================================
insert into COURSE_INSTRUCTORS (course_id, instructor_id, is_main_instructor)
values (1, 2, true),
       (1, 3, false), -- C++: GV Thanh (Chinh), GV Huong (Phu)
       (2, 2, true),  -- DSA: GV Thanh
       (3, 3, true),  -- Web: GV Huong
       (4, 4, true),  -- DB: GV Tung
       (5, 4, true),  -- Data: GV Tung
       (6, 2, true),  -- AI: GV Thanh
       (7, 5, true),  -- Network: GV Minh
       (8, 5, true); -- Cloud: GV Minh

insert into COURSE_TOPICS (course_id, topic_id)
values (1, 1), -- C++ -> Lap Trinh Co Ban
       (2, 1), -- DSA -> Lap Trinh Co Ban
       (3, 2), -- Web -> Phat Trien Web
       (4, 4), -- DB -> Co So Du Lieu
       (5, 3), -- Python -> Khoa Hoc Du Lieu
       (6, 3), -- AI -> Khoa Hoc Du Lieu
       (7, 5), -- Network -> An Ninh Mang
       (8, 2);
-- Cloud -> Phat Trien Web (Tam thoi)

-- =============================================
-- 6. seed data: SECTIONS (10 rows)
-- =============================================
insert into SECTIONS (section_id, course_id, section_name, section_order)
values
-- course 1: C++
(1, 1, 'Gioi thieu ve C++ va IDE', 1),
(2, 1, 'Bien, Kieu Du Lieu va Toan Tu', 2),
(3, 1, 'Cau Truc Dieu Khien (If, Loop)', 3),
-- course 3: Web
(4, 3, 'Tong quan ve HTML5 & CSS3', 1),
(5, 3, 'Javascript ES6 Co Ban', 2),
(6, 3, 'React Components & State', 3),
-- course 4: Database
(7, 4, 'Mo hinh ERD & Thiet ke CSDL', 1),
(8, 4, 'Truy van SQL Co ban (SELECT)', 2),
(9, 4, 'Cac loai JOIN va GROUP BY', 3),
-- course 5: Python Data
(10, 5, 'Cai dat moi truong Anaconda', 1);

-- =============================================
-- 7. seed data: LECTURES (12 rows)
-- =============================================
insert into LECTURES (section_id, lecture_name, link, duration_minutes)
values
-- C++ Lectures
(1, 'Cai dat Visual Studio Code', 'https://hcmut.edu.vn/cpp/bai1', 15),
(1, 'Chuong trinh Hello World', 'https://hcmut.edu.vn/cpp/bai2', 10),
(2, 'Cac kieu du lieu nguyen thuy', 'https://hcmut.edu.vn/cpp/bai3', 20),
(3, 'Vong lap For va While', 'https://hcmut.edu.vn/cpp/bai4', 25),
-- Web Lectures
(4, 'Cau truc DOM trong HTML', 'https://hcmut.edu.vn/web/bai1', 15),
(4, 'Flexbox va Grid System', 'https://hcmut.edu.vn/web/bai2', 30),
(5, 'Arrow Function & Destructuring', 'https://hcmut.edu.vn/web/bai3', 20),
-- Database Lectures
(7, 'Thuc the va Moi quan he', 'https://hcmut.edu.vn/db/bai1', 30),
(8, 'Cau lenh SELECT-FROM-WHERE', 'https://hcmut.edu.vn/db/bai2', 20),
(9, 'Su dung INNER JOIN', 'https://hcmut.edu.vn/db/bai3', 25),
-- Python Lectures
(10, 'Gioi thieu Jupyter Notebook', 'https://hcmut.edu.vn/data/bai1', 15),
(10, 'Cac thu vien can thiet', 'https://hcmut.edu.vn/data/bai2', 10);

-- =============================================
-- 8. seed data: TESTS (6 rows)
-- =============================================
insert into TESTS (test_id, section_id, test_name, max_attempts, time_limit_minutes, score)
values (1, 1, 'Kiem tra kien thuc nhap mon C++', 3, 15, 10),
       (2, 3, 'Bai tap ve Vong lap', 2, 30, 10),
       (3, 4, 'Quiz HTML/CSS', 3, 20, 10),
       (4, 7, 'Kiem tra thiet ke ERD', 1, 45, 10),
       (5, 8, 'Thuc hanh truy van SQL', 2, 60, 10),
       (6, 10, 'Quiz moi truong Python', 5, 10, 10);

-- =============================================
-- 9. seed data: QUESTIONS (8 rows)
-- =============================================
insert into QUESTIONS (question_id, test_id, content, type, correct_answer)
values
-- C++ Questions
(1, 1, 'Ham nao la ham chinh trong C++?', 'multiple_choice', 'main()'),
(2, 1, 'Dau cham phay dung de ket thuc lenh?', 'true_false', 'True'),
-- Web Questions
(3, 3, 'The nao dung de tao chu in dam?', 'multiple_choice', '<strong>'),
(4, 3, 'CSS la viet tat cua gi?', 'short_answer', 'Cascading Style Sheets'),
-- SQL Questions
(5, 4, 'Khoa chinh (Primary Key) phai la duy nhat?', 'true_false', 'True'),
(6, 5, 'Lenh nao dung de lay du lieu?', 'multiple_choice', 'SELECT'),
(7, 5, 'Menh de nao dung de loc du lieu?', 'multiple_choice', 'WHERE'),
-- Python Question
(8, 6, 'Thu vien nao dung ve bieu do?', 'multiple_choice', 'Matplotlib');

-- =============================================
-- 10. seed data: QUESTION_CHOICES (Wrong Answers)
-- =============================================
insert into QUESTION_CHOICES (question_id, wrong_choice)
values (1, 'start()'),
       (1, 'begin()'),
       (1, 'init()'),  -- for q1
       (3, '<bold>'),
       (3, '<bb>'),
       (3, '<heavy>'), -- for q3
       (6, 'GET'),
       (6, 'FETCH'),
       (6, 'OBTAIN'),  -- for q6
       (7, 'FILTER'),
       (7, 'SEARCH'),
       (7, 'FIND'),    -- for q7
       (8, 'NumPy'),
       (8, 'Pandas'),
       (8, 'Scikit-learn');
-- for q8

-- =============================================
-- 11. seed data: ENROLLMENTS & TRANSACTIONS
-- =============================================
-- ensure we have > 5 transactions
insert into ENROLLMENTS (student_id, course_id, enrollment_date, completion_status)
values (6, 1, '2023-09-10', 1),  -- SV An hoc C++ (Xong)
       (6, 4, '2023-09-15', 0),  -- SV An hoc DB
       (7, 1, '2023-09-12', 0),  -- SV Binh hoc C++
       (8, 3, '2023-10-01', 1),  -- SV Cuong hoc Web
       (9, 1, '2023-09-20', 1),  -- SV Dung hoc C++ (Xong)
       (10, 6, '2023-10-10', 1), -- SV Giang hoc AI
       (11, 8, '2023-11-01', 0); -- SV Hai hoc AWS

insert into TRANSACTIONS (student_id, course_id, instructor_id, price, payment_status, transaction_date)
values (6, 1, 2, 500000.00, 'completed', '2023-09-10 08:00:00'),
       (6, 4, 4, 600000.00, 'completed', '2023-09-15 09:30:00'),
       (7, 1, 2, 500000.00, 'completed', '2023-09-12 14:00:00'),
       (8, 3, 3, 1200000.00, 'completed', '2023-10-01 10:00:00'),
       (9, 1, 2, 500000.00, 'completed', '2023-09-20 15:00:00'),
       (10, 6, 2, 1500000.00, 'pending', '2023-10-10 16:00:00'), -- Giao dich dang cho
       (11, 8, 5, 2000000.00, 'failed', '2023-11-01 19:00:00');
-- Giao dich that bai (het tien)

-- =============================================
-- 12. seed data: ACTIVITY (Views, Ratings, Results)
-- =============================================

-- lecture views (sinh vien xem bai giang)
insert into LECTURE_VIEWS (student_id, lecture_id, status, view_date)
values (6, 1, 2, '2023-09-11 09:00:00'),
       (6, 2, 2, '2023-09-11 10:00:00'), -- SV An xem C++
       (9, 1, 2, '2023-09-21 20:00:00'),
       (9, 2, 2, '2023-09-21 21:00:00'), -- SV Dung xem C++
       (7, 1, 1, '2023-09-13 14:00:00'), -- SV Binh dang xem do
       (8, 4, 0, '2023-10-02 08:00:00');
-- SV Cuong chua xem

-- test results (ket qua thi)
insert into TEST_RESULTS (student_id, test_id, actual_score, start_time, submit_time, status)
values (6, 1, 10.0, '2023-09-12 09:00:00', '2023-09-12 09:15:00', 2), -- SV An 10 diem
       (9, 1, 8.5, '2023-09-22 10:00:00', '2023-09-22 10:14:00', 2),  -- SV Dung 8.5 diem
       (7, 1, 4.0, '2023-09-14 15:00:00', '2023-09-14 15:15:00', 2),
       (8, 1, 9.0, '2023-09-13 15:00:00', '2023-09-13 15:20:00', 2);
-- SV Binh rot mon

-- course ratings (danh gia)
insert into COURSE_RATINGS (student_id, course_id, rating, comment, rating_date)
values (6, 1, 5, 'Khoa hoc rat hay, thay Thanh day de hieu.', '2023-10-01 10:00:00'),
       (9, 1, 4, 'Noi dung tot nhung am thanh hoi nho.', '2023-10-05 09:00:00'),
       (7, 1, 3, 'Bai tap hoi kho so voi nguoi moi.', '2023-09-25 10:00:00'),
       (8, 1, 4, 'Tot', '2023-09-24 10:00:00');

-- certificates (chung chi - chi cap cho nguoi da xong)
insert into CERTIFICATES (student_id, course_id, issued_date)
values (6, 1, '2023-10-02'), -- SV An nhan chung chi C++
       (9, 1, '2023-10-06'), -- SV Dung nhan chung chi C++
       (8, 3, '2023-10-06'), -- cuong nhan chung chi web
       (10, 6, '2023-10-7'); -- giang nhan chung chi ai

DELIMITER //
DROP FUNCTION IF EXISTS f_ClassifyStudent //
CREATE FUNCTION f_ClassifyStudent(p_student_id INT) 
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(5, 2);
    DECLARE v_classification VARCHAR(50);
    
    -- 1. Gọi lại hàm tính GPA đã có (hoặc tính trực tiếp)
    SELECT AVG(actual_score) INTO v_gpa
    FROM TEST_RESULTS
    WHERE student_id = p_student_id;
    
    -- 2. Sử dụng IF / ELSEIF để phân loại
    IF v_gpa IS NULL THEN
        SET v_classification = 'Chưa có điểm';
    ELSEIF v_gpa >= 9.0 THEN
        SET v_classification = 'Xuất Sắc (Excellent)';
    ELSEIF v_gpa >= 8.0 THEN
        SET v_classification = 'Giỏi (Good)';
    ELSEIF v_gpa >= 6.5 THEN
        SET v_classification = 'Khá (Fair)';
    ELSEIF v_gpa >= 5.0 THEN
        SET v_classification = 'Trung Bình (Average)';
    ELSE
        SET v_classification = 'Yếu (Weak)';
    END IF;
    
    RETURN v_classification;
END //

-- 1. Hàm tính điểm trung bình (GPA) của sinh viên dựa trên kết quả thi
DROP FUNCTION IF EXISTS f_CalculateGPA //
CREATE FUNCTION f_CalculateGPA(p_student_id INT) 
RETURNS DECIMAL(5, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(5, 2);
    
    -- Tính trung bình cộng cột actual_score trong bảng TEST_RESULTS
    SELECT AVG(actual_score) INTO v_gpa
    FROM TEST_RESULTS
    WHERE student_id = p_student_id;
    
    -- Nếu sinh viên chưa thi bài nào (NULL), trả về 0.00
    IF v_gpa IS NULL THEN
        RETURN 0.00;
    END IF;
    
    RETURN v_gpa;
END //

-- 2. Hàm tính tổng tiền sinh viên đã chi trả (chỉ tính giao dịch thành công)
DROP FUNCTION IF EXISTS f_CalculateTotalSpent //
CREATE FUNCTION f_CalculateTotalSpent(p_student_id INT) 
RETURNS DECIMAL(15, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15, 2);
    
    SELECT SUM(price) INTO v_total
    FROM TRANSACTIONS
    WHERE student_id = p_student_id AND payment_status = 'completed';
    
    IF v_total IS NULL THEN
        RETURN 0.00;
    END IF;
    
    RETURN v_total;
END //


DROP PROCEDURE IF EXISTS sp_ReportHighRevenueInstructors //
CREATE PROCEDURE sp_ReportHighRevenueInstructors(
    IN p_min_revenue DECIMAL(15, 2) -- Tham số lọc doanh thu tối thiểu
)
BEGIN
    -- 1. Kiểm tra tham số đầu vào (Validation)
    IF p_min_revenue < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Mức doanh thu tối thiểu không được là số âm!';
    ELSE
        -- 2. Truy vấn phức tạp với GROUP BY và HAVING
        SELECT 
            u.user_id,
            CONCAT(u.last_name, ' ', u.first_name) AS InstructorName,
            i.teaching_field,
            COUNT(t.transaction_id) AS TotalTransactions,
            SUM(t.price) AS TotalRevenue
        FROM INSTRUCTORS i
        JOIN USERS u ON i.instructor_id = u.user_id
        JOIN TRANSACTIONS t ON i.instructor_id = t.instructor_id
        WHERE t.payment_status = 'completed' -- Chỉ lấy giao dịch thành công
        GROUP BY i.instructor_id, u.last_name, u.first_name, i.teaching_field
        HAVING TotalRevenue >= p_min_revenue -- Chỉ hiện người có doanh thu >= mức nhập vào
        ORDER BY TotalRevenue DESC; -- Sắp xếp từ cao xuống thấp
    END IF;
END //

DROP PROCEDURE IF EXISTS sp_AutoIssueCertificates //

CREATE PROCEDURE sp_AutoIssueCertificates(
    OUT p_count_issued INT -- Trả về số lượng chứng chỉ vừa cấp mới
)
BEGIN
    -- Khai báo biến để lưu dữ liệu khi duyệt vòng lặp
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    
    -- Khai báo CURSOR (Con trỏ) để lấy danh sách các sinh viên đã hoàn thành khóa học
    DECLARE cur_completed_students CURSOR FOR 
        SELECT student_id, course_id 
        FROM ENROLLMENTS 
        WHERE completion_status = 1;
        
    -- Khai báo handler để nhận biết khi nào hết dữ liệu (kết thúc vòng lặp)
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET p_count_issued = 0;

    -- Bắt đầu mở con trỏ
    OPEN cur_completed_students;

    -- Bắt đầu vòng lặp (Tương đương FOR / WHILE)
    read_loop: LOOP
        -- Lấy từng dòng dữ liệu gán vào biến
        FETCH cur_completed_students INTO v_student_id, v_course_id;

        -- Nếu hết dữ liệu thì thoát vòng lặp
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- LOGIC KIỂM TRA: Nếu chưa có chứng chỉ thì cấp mới
        IF NOT EXISTS (SELECT 1 FROM CERTIFICATES WHERE student_id = v_student_id AND course_id = v_course_id) THEN
            INSERT INTO CERTIFICATES (student_id, course_id, issued_date)
            VALUES (v_student_id, v_course_id, CURRENT_DATE());
            
            -- Tăng biến đếm
            SET p_count_issued = p_count_issued + 1;
        END IF;
        
    END LOOP;

    -- Đóng con trỏ
    CLOSE cur_completed_students;
END //
-- 3. Thủ tục đăng ký khóa học (có kiểm tra điều kiện)
DROP PROCEDURE IF EXISTS sp_RegisterCourse //
CREATE PROCEDURE sp_RegisterCourse(
    IN p_student_id INT,
    IN p_course_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_student_exists INT;
    DECLARE v_course_exists INT;
    DECLARE v_already_enrolled INT;
    
    -- Kiểm tra sinh viên có tồn tại không
    SELECT COUNT(*) INTO v_student_exists FROM STUDENTS WHERE student_id = p_student_id;
    
    -- Kiểm tra khóa học có tồn tại không
    SELECT COUNT(*) INTO v_course_exists FROM COURSES WHERE course_id = p_course_id;
    
    IF v_student_exists = 0 THEN
        SET p_message = 'Lỗi: Sinh viên không tồn tại.';
    ELSEIF v_course_exists = 0 THEN
        SET p_message = 'Lỗi: Khóa học không tồn tại.';
    ELSE
        -- Kiểm tra xem đã đăng ký chưa
        SELECT COUNT(*) INTO v_already_enrolled 
        FROM ENROLLMENTS 
        WHERE student_id = p_student_id AND course_id = p_course_id;
        
        IF v_already_enrolled > 0 THEN
            SET p_message = 'Lỗi: Sinh viên đã đăng ký khóa học này rồi.';
        ELSE
            -- Thỏa mãn mọi điều kiện -> Insert
            INSERT INTO ENROLLMENTS (student_id, course_id, enrollment_date, completion_status)
            VALUES (p_student_id, p_course_id, CURRENT_DATE(), 0);
            
            SET p_message = 'Thành công: Đăng ký khóa học hoàn tất.';
        END IF;
    END IF;
END //

-- 4. Thủ tục báo cáo doanh thu theo giảng viên
DROP PROCEDURE IF EXISTS sp_GetInstructorRevenue //
CREATE PROCEDURE sp_GetInstructorRevenue()
BEGIN
    SELECT 
        u.user_id AS InstructorID,
        CONCAT(u.last_name, ' ', u.first_name) AS InstructorName,
        i.teaching_field AS Field,
        COUNT(t.transaction_id) AS TotalTransactions,
        COALESCE(SUM(t.price), 0) AS TotalRevenue
    FROM INSTRUCTORS i
    JOIN USERS u ON i.instructor_id = u.user_id
    LEFT JOIN TRANSACTIONS t ON i.instructor_id = t.instructor_id AND t.payment_status = 'completed'
    GROUP BY i.instructor_id, u.last_name, u.first_name, i.teaching_field
    ORDER BY TotalRevenue DESC;
END //



-- 5. Trigger cập nhật số lượng bài giảng trong bảng COURSES khi thêm bài giảng mới
DROP TRIGGER IF EXISTS trg_AfterInsertLecture //
CREATE TRIGGER trg_AfterInsertLecture
AFTER INSERT ON LECTURES
FOR EACH ROW
BEGIN
    DECLARE v_course_id INT;
    
    -- Lấy course_id từ bảng SECTIONS dựa vào section_id của bài giảng vừa thêm
    SELECT course_id INTO v_course_id
    FROM SECTIONS
    WHERE section_id = NEW.section_id;
    
    -- Cập nhật tăng số lượng lecture lên 1
    UPDATE COURSES
    SET total_lectures = total_lectures + 1
    WHERE course_id = v_course_id;
END //

-- 6. Trigger kiểm tra điểm thi hợp lệ (Điểm đạt được không được lớn hơn điểm tối đa của đề)
DROP TRIGGER IF EXISTS trg_BeforeInsertResult //
CREATE TRIGGER trg_BeforeInsertResult
BEFORE INSERT ON TEST_RESULTS
FOR EACH ROW
BEGIN
    DECLARE v_max_score INT;
    
    -- Lấy điểm tối đa của bài test
    SELECT score INTO v_max_score
    FROM TESTS
    WHERE test_id = NEW.test_id;
    
    -- So sánh điểm sinh viên đạt được với điểm tối đa
    IF NEW.actual_score > v_max_score THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Điểm thực tế không được lớn hơn điểm tối đa của bài kiểm tra!';
    END IF;
END //

DROP TRIGGER IF EXISTS trg_ValidatePaymentAmount //

CREATE TRIGGER trg_ValidatePaymentAmount
BEFORE INSERT ON TRANSACTIONS
FOR EACH ROW
BEGIN
    DECLARE v_course_price DECIMAL(10, 2);
    
    -- Lấy giá gốc của khóa học
    SELECT price INTO v_course_price
    FROM COURSES
    WHERE course_id = NEW.course_id;
    
    -- Kiểm tra: Nếu số tiền trả (NEW.price) thấp hơn giá khóa học -> Báo lỗi
    -- (Trừ trường hợp được hoàn tiền 'refunded' thì không check)
    IF NEW.payment_status != 'refunded' AND NEW.price < v_course_price THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Số tiền thanh toán không được thấp hơn giá khóa học!';
    END IF;
END //

DELIMITER ;



-- 5. TẠO USER ĐỂ CHẠY APP (PHẦN NÀY QUAN TRỌNG ĐỂ LOGIN APP)
-- Drop user nếu đã tồn tại để tránh lỗi
DROP USER IF EXISTS 'sManager'@'localhost';
DROP USER IF EXISTS 'myadmin'@'localhost';
CREATE USER 'sManager'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'myadmin'@'localhost' identified by 'supermen';
GRANT ALL PRIVILEGES ON BTL3.* TO 'myadmin'@'localhost';
GRANT ALL PRIVILEGES ON BTL3.* TO 'sManager'@'localhost';
FLUSH PRIVILEGES;

SELECT 'CAI DAT THANH CONG TOAN BO HE THONG!' AS Message;