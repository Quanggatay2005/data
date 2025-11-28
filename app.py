import tkinter as tk
from tkinter import messagebox, ttk
import mysql.connector

# --- CẤU HÌNH KẾT NỐI (Đã đổi sang BTL3) ---
DB_CONFIG = {
    'host': '127.0.0.2',
    'database': 'BTL3', 
    'port': 3306
}

class StudentApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Hệ Thống Quản Lý Đào Tạo (BTL3)")
        self.root.geometry("1000x650")
        self.conn = None
        self.create_login_screen()

    # ================= 1. LOGIN =================
    def create_login_screen(self):
        self.clear_screen()
        frame = tk.Frame(self.root)
        frame.pack(pady=60)

        tk.Label(frame, text="ĐĂNG NHẬP ", font=("Arial", 18, "bold"), fg="#333").pack(pady=15)
        
        tk.Label(frame, text="Username (DB User):").pack()
        self.entry_user = tk.Entry(frame)
        self.entry_user.insert(0, "sManager")
        self.entry_user.pack(pady=5)

        tk.Label(frame, text="Password:").pack()
        self.entry_pass = tk.Entry(frame, show="*")
        self.entry_pass.insert(0, "123456")
        self.entry_pass.pack(pady=5)

        tk.Button(frame, text="Đăng Nhập", command=self.login, bg="#4CAF50", fg="white", font=("Arial", 10, "bold"), width=15).pack(pady=20)

    def login(self):
        try:
            self.conn = mysql.connector.connect(
                user=self.entry_user.get(), 
                password=self.entry_pass.get(), 
                **DB_CONFIG
            )
            messagebox.showinfo("Kết nối", "Đăng nhập thành công vào BTL3!")
            self.create_dashboard()
        except mysql.connector.Error as err:
            messagebox.showerror("Lỗi Kết Nối", f"Chi tiết lỗi:\n{err}")

    # ================= 2. DASHBOARD & MENU =================
    def create_dashboard(self):
        self.clear_screen()
        
        # Menu Bar
        menu_frame = tk.Frame(self.root, bg="#f0f0f0", height=40)
        menu_frame.pack(fill="x")
        
        btn_style = {"bg": "#2196F3", "fg": "white", "padx": 10, "pady": 5, "bd": 0}
        
        tk.Button(menu_frame, text="QL Sinh Viên & Tổng Chi", command=self.view_students, **btn_style).pack(side="left", padx=2)
        tk.Button(menu_frame, text="Đăng Ký Khóa Học (Proc)", command=self.view_register, **btn_style).pack(side="left", padx=2)
        tk.Button(menu_frame, text="Báo Cáo Doanh Thu (Proc)", command=self.view_revenue, **btn_style).pack(side="left", padx=2)
        tk.Button(menu_frame, text="Đăng Xuất", command=self.logout, bg="#F44336", fg="white", padx=10, pady=5, bd=0).pack(side="right", padx=2)

        self.content_frame = tk.Frame(self.root, padx=10, pady=10)
        self.content_frame.pack(fill="both", expand=True)
        
        self.view_students() # Mặc định vào màn hình sinh viên

    # ================= 3. QUẢN LÝ SINH VIÊN (Dùng Function f_CalculateTotalSpent) =================
    def view_students(self):
        self.clear_content()
        tk.Label(self.content_frame, text="DANH SÁCH SINH VIÊN & CHI TIÊU", font=("Arial", 14, "bold")).pack(pady=10)

        # Bảng hiển thị
        cols = ("ID", "Username", "Họ Tên", "Email", "Ngày Nhập Học", "Tổng Đã Chi (VND)")
        self.tree = ttk.Treeview(self.content_frame, columns=cols, show="headings", height=15)
        
        for col in cols:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=150)
        self.tree.pack(fill="both", expand=True)

        # Nút tác vụ
        action_frame = tk.Frame(self.content_frame)
        action_frame.pack(pady=10)
        tk.Button(action_frame, text="Tải Dữ Liệu (Load)", command=self.load_student_data).pack(side="left", padx=5)
        tk.Button(action_frame, text="Xóa Sinh Viên", command=self.delete_student, bg="red", fg="white").pack(side="left", padx=5)

        # Form thêm mới
        form = tk.LabelFrame(self.content_frame, text="Thêm Sinh Viên Mới", padx=10, pady=10)
        form.pack(fill="x")
        
        tk.Label(form, text="Username:").grid(row=0, column=0); self.en_user = tk.Entry(form); self.en_user.grid(row=0, column=1)
        tk.Label(form, text="Email:").grid(row=0, column=2); self.en_email = tk.Entry(form); self.en_email.grid(row=0, column=3)
        tk.Label(form, text="Họ:").grid(row=1, column=0); self.en_last = tk.Entry(form); self.en_last.grid(row=1, column=1)
        tk.Label(form, text="Tên:").grid(row=1, column=2); self.en_first = tk.Entry(form); self.en_first.grid(row=1, column=3)
        
        tk.Button(form, text="Lưu Lại", command=self.add_student, bg="green", fg="white").grid(row=2, column=1, pady=10)

        self.load_student_data()

    def load_student_data(self):
        try:
            cursor = self.conn.cursor()
            # [QUAN TRỌNG] Gọi Function f_CalculateTotalSpent trong câu SELECT
            sql = """
                SELECT 
                    s.student_id, 
                    u.username, 
                    CONCAT(u.last_name, ' ', u.first_name), 
                    u.email, 
                    s.enrollment_date,
                    f_CalculateTotalSpent(s.student_id) -- Gọi Function tính tiền
                FROM STUDENTS s
                JOIN USERS u ON s.student_id = u.user_id
            """
            cursor.execute(sql)
            rows = cursor.fetchall()
            
            for item in self.tree.get_children(): self.tree.delete(item)
            for row in rows:
                # Format tiền cho đẹp (ví dụ: 1000000.00 -> 1,000,000)
                formatted_row = list(row)
                money = row[5] if row[5] else 0
                formatted_row[5] = f"{money:,.0f}"
                self.tree.insert("", "end", values=formatted_row)
                
        except mysql.connector.Error as err:
            messagebox.showerror("Lỗi SQL", str(err))

    def add_student(self):
        try:
            cursor = self.conn.cursor()
            # Insert User (Không còn user_code nữa)
            sql_user = "INSERT INTO USERS (username, email, first_name, last_name, password, role) VALUES (%s, %s, %s, %s, '123456', 2)"
            val_user = (self.en_user.get(), self.en_email.get(), self.en_first.get(), self.en_last.get())
            cursor.execute(sql_user, val_user)
            new_id = cursor.lastrowid
            
            # Insert Student (Trigger 'trg_AfterInsertLecture' ko liên quan ở đây, nhưng hệ thống vẫn chạy ổn)
            sql_student = "INSERT INTO STUDENTS (student_id, enrollment_date) VALUES (%s, CURRENT_DATE())"
            cursor.execute(sql_student, (new_id,))
            
            self.conn.commit()
            messagebox.showinfo("Thành công", f"Đã thêm sinh viên ID: {new_id}")
            self.load_student_data()
        except mysql.connector.Error as err:
            messagebox.showerror("Lỗi", str(err))

    def delete_student(self):
        sel = self.tree.selection()
        if not sel: return
        sid = self.tree.item(sel)['values'][0]
        if messagebox.askyesno("Xác nhận", "Xóa sinh viên này?"):
            try:
                self.conn.cursor().execute("DELETE FROM USERS WHERE user_id = %s", (sid,))
                self.conn.commit()
                self.load_student_data()
            except Exception as e: messagebox.showerror("Lỗi", str(e))

    # ================= 4. ĐĂNG KÝ KHÓA HỌC (Dùng Procedure sp_RegisterCourse) =================
    def view_register(self):
        self.clear_content()
        tk.Label(self.content_frame, text="ĐĂNG KÝ KHÓA HỌC (Gọi Procedure)", font=("Arial", 14, "bold")).pack(pady=20)

        input_frame = tk.Frame(self.content_frame)
        input_frame.pack()

        tk.Label(input_frame, text="ID Sinh Viên:").grid(row=0, column=0, padx=5, pady=5)
        self.reg_sid = tk.Entry(input_frame); self.reg_sid.grid(row=0, column=1, padx=5, pady=5)

        tk.Label(input_frame, text="ID Khóa Học:").grid(row=1, column=0, padx=5, pady=5)
        self.reg_cid = tk.Entry(input_frame); self.reg_cid.grid(row=1, column=1, padx=5, pady=5)

        tk.Button(input_frame, text="Đăng Ký Ngay", command=self.run_register_proc, bg="#FF9800", fg="white", font=("Arial", 11)).grid(row=2, column=0, columnspan=2, pady=20)
        
        # Hướng dẫn
        note = """
        Lưu ý: Chức năng này sẽ gọi 'sp_RegisterCourse'.
        Procedure này sẽ tự động kiểm tra:
        1. Sinh viên có tồn tại không?
        2. Khóa học có tồn tại không?
        3. Đã đăng ký chưa?
        Sau đó trả về thông báo lỗi hoặc thành công.
        """
        tk.Label(self.content_frame, text=note, justify="left", fg="gray").pack()

    def run_register_proc(self):
        sid = self.reg_sid.get()
        cid = self.reg_cid.get()
        if not sid or not cid: return

        try:
            cursor = self.conn.cursor()
            # Gọi Stored Procedure có tham số OUT
            # args=(in_param1, in_param2, out_param) -> out_param để là 0 hoặc ''
            args = (int(sid), int(cid), '') 
            result_args = cursor.callproc('sp_RegisterCourse', args)
            
            # Lấy thông báo từ tham số thứ 3 (index 2)
            msg = result_args[2] 
            
            if "Thành công" in msg:
                messagebox.showinfo("Kết quả", msg)
            else:
                messagebox.showwarning("Kết quả", msg)
                
            self.conn.commit()
        except mysql.connector.Error as err:
            messagebox.showerror("Lỗi SQL", str(err))
        except ValueError:
            messagebox.showerror("Lỗi", "Vui lòng nhập số ID hợp lệ")

    # ================= 5. BÁO CÁO DOANH THU (Dùng Procedure sp_GetInstructorRevenue) =================
    def view_revenue(self):
        self.clear_content()
        tk.Label(self.content_frame, text="DOANH THU GIẢNG VIÊN", font=("Arial", 14, "bold")).pack(pady=10)

        cols = ("ID GV", "Tên Giảng Viên", "Lĩnh Vực", "Số Giao Dịch", "Tổng Doanh Thu (VND)")
        tree = ttk.Treeview(self.content_frame, columns=cols, show="headings", height=15)
        for c in cols: 
            tree.heading(c, text=c)
            tree.column(c, width=150)
        tree.pack(fill="both", expand=True)

        try:
            cursor = self.conn.cursor()
            # Gọi Procedure
            cursor.callproc('sp_GetInstructorRevenue')
            
            for result in cursor.stored_results():
                for row in result.fetchall():
                    # Format tiền
                    fmt_row = list(row)
                    fmt_row[4] = f"{row[4]:,.0f}"
                    tree.insert("", "end", values=fmt_row)
        except Exception as e:
            messagebox.showerror("Lỗi", str(e))

    # Utils
    def logout(self):
        if self.conn: self.conn.close()
        self.create_login_screen()

    def clear_screen(self):
        for w in self.root.winfo_children(): w.destroy()

    def clear_content(self):
        for w in self.content_frame.winfo_children(): w.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = StudentApp(root)
    root.mainloop()