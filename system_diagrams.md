# Dokumentasi Diagram Sistem - Jejak Hadir SMK

Dokumen ini berisi visualisasi arsitektur dan alur kerja aplikasi **Jejak Hadir SMK** (Sistem Absensi/Presensi Siswa SMK). Visualisasi disajikan dalam 3 bentuk utama:
1. **Entity Relationship Diagram (ERD)** — Struktur dan hubungan data database.
2. **Flowchart (Alur Kerja)** — Alur proses utama (Login, Absensi, CRUD Riwayat).
3. **Class Diagram** — Struktur kode, class, method, property, dan hubungannya.

---

## 1. Entity Relationship Diagram (ERD)

ERD ini menunjukkan struktur penyimpanan database lokal menggunakan **SQLite** (`attendance.db`). Terdapat dua entitas utama yaitu **Users** (menyimpan data siswa) dan **Attendances** (menyimpan data riwayat presensi/absensi).

```mermaid
erDiagram
    USERS {
        int id PK "Primary Key (Auto Increment)"
        string fullname "Nama Lengkap Siswa"
        string email UK "Email (Unique, untuk Login)"
        string password "Password terenkripsi/plain"
        string phone "Nomor Telepon/HP"
        string created_at "Tanggal Registrasi Akun"
    }

    ATTENDANCES {
        int id PK "Primary Key (Auto Increment)"
        int user_id FK "Foreign Key -> USERS.id"
        string check_in "Waktu Check-In (Absen Masuk)"
        string check_out "Waktu Check-Out (Absen Keluar) - Nullable"
        double latitude "Koordinat Lintang GPS"
        double longitude "Koordinat Bujur GPS"
        string address "Alamat Hasil Geocoding"
        string status "Status Kehadiran (Hadir / Sakit / Izin / Selesai)"
        string created_at "Tanggal Log Absensi"
    }

    USERS ||--o{ ATTENDANCES : "memiliki (1 to N)"
```

### Penjelasan Detail Hubungan ERD:
* **USERS (Siswa)**: Berfungsi untuk menyimpan informasi profil siswa SMK. Setiap siswa didefinisikan dengan atribut unik seperti `email` untuk otentikasi login.
* **ATTENDANCES (Presensi)**: Menyimpan detail presensi harian siswa yang mencakup koordinat lokasi geografis (`latitude` & `longitude`), alamat lengkap (`address`), serta waktu masuk (`check_in`) dan keluar (`check_out`). Atribut `status` membedakan jenis presensi seperti "Hadir", "Sakit", "Izin", atau "Selesai" (setelah check-out).
* **Kardinalitas**: Hubungan **1-to-N** (One-to-Many). Satu orang Siswa (`USERS`) dapat memiliki banyak catatan presensi harian (`ATTENDANCES`), tetapi setiap baris data presensi hanya dimiliki oleh tepat satu Siswa.

---

## 2. Flowchart (Alur Kerja Sistem)

Alur kerja aplikasi presensi Jejak Hadir SMK terbagi menjadi beberapa proses utama: Alur Autentikasi (Login/Register), Alur Melakukan Presensi (Check-in/Check-out), dan Alur Manajemen Riwayat (CRUD).

### A. Alur Autentikasi & Masuk Aplikasi
```mermaid
graph TD
    Start([Mulai Aplikasi]) --> Splash[Splash Screen]
    Splash --> CheckSession{Apakah Session Aktif?}
    
    %% Jika tidak ada session
    CheckSession -- Tidak --> LoginScreen[Tampilan Login]
    LoginScreen --> CheckReg{Belum Punya Akun?}
    CheckReg -- Ya --> RegisterScreen[Registrasi Akun Baru]
    RegisterScreen --> SaveUser[Simpan ke SQLite 'users']
    SaveUser --> LoginScreen
    
    CheckReg -- Tidak --> InputLogin[Input Email & Password]
    InputLogin --> AuthProcess{Validasi di SQLite?}
    AuthProcess -- Tidak Valid --> AlertFail[Tampilkan Pesan Error]
    AlertFail --> LoginScreen
    AuthProcess -- Valid --> SaveSession[Simpan Session Siswa]
    
    %% Jika ada session
    CheckSession -- Ya --> HomeScreen[Menu Utama / Dashboard]
    SaveSession --> HomeScreen
    
    HomeScreen --> End([Selesai])
```

### B. Alur Presensi Siswa (Check-In & Check-Out)
```mermaid
graph TD
    Start([Mulai Absen]) --> HomeScreen[Menu Utama / Dashboard]
    HomeScreen --> CheckStatus{Sudah Check-In Hari Ini?}
    
    %% Jika belum check-in
    CheckStatus -- Belum --> CheckInPage[Halaman Check-In]
    CheckInPage --> GetGPS[Ambil Lokasi Realtime & Google Maps]
    GetGPS --> SelectStatus[Pilih Status: Hadir / Sakit / Izin]
    SelectStatus --> ClickCheckIn[Klik Tombol Check-In]
    ClickCheckIn --> SaveCheckIn[Simpan ke Tabel 'attendances'<br>check_out = NULL]
    SaveCheckIn --> SuccessCheckIn[Pesan: Check-In Berhasil]
    SuccessCheckIn --> HomeScreen
    
    %% Jika sudah check-in tapi belum check-out
    CheckStatus -- Sudah Check-In --> CheckOutPage[Halaman Check-Out]
    CheckOutPage --> ShowActive[Tampilkan Data Lokasi Check-In]
    ShowActive --> GetGPSOut[Ambil Lokasi Keluar Realtime]
    GetGPSOut --> ClickCheckOut[Klik Tombol Check-Out]
    ClickCheckOut --> UpdateCheckOut[Update Tabel 'attendances'<br>Set check_out & status='Selesai']
    UpdateCheckOut --> SuccessCheckOut[Pesan: Check-Out Berhasil]
    SuccessCheckOut --> HomeScreen
    
    %% Jika sudah selesai keduanya
    CheckStatus -- Sudah Selesai Keduanya --> Disabled[Tombol Presensi Dinonaktifkan]
    Disabled --> HomeScreen
```

### C. Alur Manajemen Riwayat Absensi (Fitur CRUD)
```mermaid
graph TD
    Start([Akses Riwayat]) --> HistoryScreen[Tampilan Riwayat Presensi]
    HistoryScreen --> ReadList[Load Semua Absensi Siswa dari SQLite]
    ReadList --> ShowList[Tampilkan Daftar Riwayat]
    
    %% Pilihan Aksi
    ShowList --> Options{Pilih Aksi CRUD}
    
    %% Create/Add Manual
    Options -- "Tambah Manual (Create)" --> AddForm[Form Tambah Absensi]
    AddForm --> InputData[Input Waktu, Status & Alamat]
    InputData --> InsertDB[Simpan ke Tabel 'attendances']
    InsertDB --> RefreshList[Refresh Riwayat]
    
    %% Update/Edit
    Options -- "Edit Absensi (Update)" --> EditForm[Form Edit Absensi]
    EditForm --> ModifyData[Ubah Data Presensi]
    ModifyData --> UpdateDB[Update data di Tabel 'attendances']
    UpdateDB --> RefreshList
    
    %% Delete
    Options -- "Hapus Absensi (Delete)" --> ConfirmDelete{Konfirmasi Hapus?}
    ConfirmDelete -- Ya --> DeleteDB[Hapus dari Tabel 'attendances']
    ConfirmDelete -- Tidak --> ShowList
    DeleteDB --> RefreshList
    
    RefreshList --> ShowList
```

---

## 3. Class Diagram

Class diagram ini menggambarkan struktur arsitektur berorientasi objek yang diterapkan pada aplikasi Jejak Hadir SMK dengan memisahkan tanggung jawab menggunakan arsitektur berlapis (Layered Architecture): **View/Screen**, **Controller**, **Repository**, dan **Model**.

```mermaid
classDiagram
    %% Core/Database Layer
    class DatabaseHelper {
        +Database _database$
        +database: Future~Database~$
        +initDatabase() Future~Database~$
    }
    
    class DatabaseService {
        +db: Future~Database~
        +insert(String table, Map data) Future~int~
        +getAll(String table) Future~List~
        +update(String table, Map data, int id) Future~int~
        +delete(String table, int id) Future~int~
    }

    %% Models Layer
    class UserModel {
        +int id
        +String fullname
        +String email
        +String password
        +String phone
        +String createdAt
        +toMap() Map~String, dynamic~
        +fromMap(Map map) UserModel$
    }

    class AttendanceModel {
        +int id
        +int userId
        +String checkIn
        +String checkOut
        +double latitude
        +double longitude
        +String address
        +String status
        +String createdAt
        +toMap() Map~String, dynamic~
        +fromMap(Map map) AttendanceModel$
    }

    class LocationModel {
        +double latitude
        +double longitude
        +String address
        +toMap() Map~String, dynamic~
        +fromMap(Map map) LocationModel$
    }

    %% Repositories Layer
    class AuthRepository {
        +register(UserModel user) Future~int~
        +login(String email, String password) Future~UserModel?~
    }

    class AttendanceRepository {
        +checkIn(AttendanceModel attendance) Future~int~
        +getAttendanceByUser(int userId) Future~List~
        +getActiveAttendanceByUser(int userId) Future~AttendanceModel?~
        +checkOut(int attendanceId, String checkOut) Future~int~
    }

    class HistoryRepository {
        +getHistory(int userId) Future~List~
        +insertAttendance(AttendanceModel attendance) Future~int~
        +updateAttendance(AttendanceModel attendance) Future~int~
        +deleteAttendance(int id) Future~int~
    }

    class ProfileRepository {
        +getUserById(int userId) Future~UserModel?~
        +updateProfile(UserModel user) Future~int~
    }

    %% Controllers Layer
    class AuthController {
        -AuthRepository _repository
        +register(UserModel user) Future~int~
        +login(String email, String password) Future~UserModel?~
    }

    class AttendanceController {
        -AttendanceRepository _repository
        +checkIn(AttendanceModel attendance) Future~int~
        +checkOut(int attendanceId, String checkOut) Future~int~
        +getAttendanceByUser(int userId) Future~List~
        +getActiveAttendanceByUser(int userId) Future~AttendanceModel?~
    }

    class HistoryController {
        -HistoryRepository _repository
        +getHistory(int userId) Future~List~
        +addAttendance(AttendanceModel attendance) Future~int~
        +updateAttendance(AttendanceModel attendance) Future~int~
        +deleteAttendance(int id) Future~int~
    }

    class ProfileController {
        -ProfileRepository _repository
        +getUserById(int userId) Future~UserModel?~
        +updateProfile(UserModel user) Future~int~
    }

    %% Hubungan Asosiasi dan Dependensi
    DatabaseHelper <-- AuthRepository : uses
    DatabaseHelper <-- AttendanceRepository : uses
    DatabaseHelper <-- HistoryRepository : uses
    DatabaseHelper <-- ProfileRepository : uses
    
    AuthRepository <-- AuthController : uses
    AttendanceRepository <-- AttendanceController : uses
    HistoryRepository <-- HistoryController : uses
    ProfileRepository <-- ProfileController : uses
    
    AuthController ..> UserModel : operates on
    ProfileController ..> UserModel : operates on
    AttendanceController ..> AttendanceModel : operates on
    HistoryController ..> AttendanceModel : operates on
    
    AttendanceModel ..> LocationModel : uses coordinates
```

### Penjelasan Komponen Class Diagram:
1. **Model Layer (`UserModel`, `AttendanceModel`, `LocationModel`)**:
   * Class representasi data (POJO/Dart data class) untuk memetakan objek dari/ke database SQLite.
2. **Repository Layer (`AuthRepository`, `AttendanceRepository`, dll.)**:
   * Bertanggung jawab melakukan interaksi SQL mentah (`query`, `insert`, `update`, `delete`) ke database SQLite via `DatabaseHelper`.
3. **Controller Layer (`AuthController`, `AttendanceController`, dll.)**:
   * Bertindak sebagai pengatur logika bisnis (*business logic layer*). Menghubungkan UI/Screen dengan data di Repository.
4. **Helper Layer (`DatabaseHelper`, `DatabaseService`)**:
   * Mengatur inisialisasi koneksi database SQLite (`openDatabase`), pembuatan tabel, dan operasi database tingkat rendah.
