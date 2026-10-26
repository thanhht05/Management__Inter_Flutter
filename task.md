# Hướng Dẫn Tích Hợp API Backend Cho Ứng Dụng Flutter (ManageIntern)

Tài liệu này tổng hợp chi tiết các API dễ tiếp cận nhất từ backend để bạn bắt đầu xây dựng ứng dụng Flutter quản lý thực tập sinh (**ManageIntern**), bao gồm cấu trúc dữ liệu, request/response mẫu và gợi ý cách tổ chức code trong Flutter.

---

## 1. Cấu Trúc Response Chung Của Backend

Backend Spring Boot sử dụng chuẩn bọc response thống nhất qua class `ApiResponse<T>` và `PageResponse<T>`.

### 1.1. Cấu trúc Response cơ bản (`ApiResponse<T>`)
Mọi request thành công hay thất bại đều trả về cấu trúc:
```json
{
  "success": true,
  "code": "SUCCESS_CODE_NAME",
  "statusCode": 200,
  "message": "Mô tả kết quả thành công hoặc thông báo lỗi",
  "data": { ... },
  "timestamp": "2026-10-26T06:50:00.000Z"
}
```

### 1.2. Cấu trúc Phân trang (`PageResponse<T>`)
Đối với các API lấy danh sách có phân trang, phần `data` sẽ có dạng:
```json
{
  "items": [ ... ],
  "currentPage": 0,
  "totalPages": 5,
  "totalItems": 48,
  "pageSize": 10
}
```

### 1.3. Base URL & Gọi API trong Flutter
- **Android Emulator**: `http://10.0.2.2:8080` (Máy ảo Android dùng IP này để trỏ về localhost máy tính host)
- **iOS Simulator / Web**: `http://localhost:8080`
- **Thiết bị thật (Cắm cáp / Cùng Wifi)**: `http://<IP-LAN-MÁY-TÍNH>:8080` (Ví dụ: `http://192.168.1.15:8080`)

### 1.4. Cơ chế Xác thực (Bearer Token)
Ngoại trừ API `/auth/login`, tất cả các API khác đều yêu cầu gắn access token vào header HTTP:
```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

### 1.5. Model Dart mẫu dùng chung
```dart
class ApiResponse<T> {
  final bool success;
  final String? code;
  final String? message;
  final int? statusCode;
  final T? data;

  ApiResponse({
    required this.success,
    this.code,
    this.message,
    this.statusCode,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      code: json['code'],
      message: json['message'],
      statusCode: json['statusCode'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class PageResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;

  PageResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonItem,
  ) {
    var list = json['items'] as List? ?? [];
    return PageResponse<T>(
      items: list.map((item) => fromJsonItem(item)).toList(),
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
```

---

## Giai Đoạn 1: Đăng Nhập & Thông Tin Tài Khoản (Auth & Profile)

Mục tiêu học Flutter:
- Xây dựng màn hình Đăng nhập với `TextFormField`, nút `ElevatedButton`, hiển thị `CircularProgressIndicator` khi loading.
- Lưu token an toàn bằng package `flutter_secure_storage` hoặc `shared_preferences`.
- Xây dựng màn hình Profile hiển thị avatar, tên, email, vai trò (role).

---

### 1.1. Đăng nhập (Login)
* **Phương thức**: `POST`
* **URL**: `/auth/login`
* **Header**: `Content-Type: application/json` (Không cần token)
* **Request Body**:
  ```json
  {
    "username": "admin",
    "password": "Password123@"
  }
  ```
* **Response Thành công (200 OK)**:
  ```json
  {
    "success": true,
    "code": "LOGIN_SUCCESSFUL",
    "statusCode": 200,
    "message": "Đăng nhập thành công",
    "data": {
      "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
      "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
      "userResponse": {
        "id": "11111111-2222-3333-4444-555555555555",
        "email": "admin@rikai.technology",
        "fullName": "Administrator",
        "role": {
          "roleName": "ADMIN",
          "description": "Quản trị hệ thống"
        },
        "isActive": true,
        "mustChangePassword": false
      }
    }
  }
  ```
* **Xử lý phía Flutter**:
  1. Lấy `accessToken` từ `data['accessToken']`.
  2. Lưu token vào Storage cục bộ:
     ```dart
     await storage.write(key: 'access_token', value: result.data!.accessToken);
     ```
  3. Chuyển hướng sang màn hình Dashboard / Danh sách Intern (`Navigator.pushReplacementNamed(...)`).

---

### 1.2. Lấy thông tin cá nhân (Get My Info)
* **Phương thức**: `GET`
* **URL**: `/users/get-my-info`
* **Header**:
  ```http
  Authorization: Bearer <access_token>
  ```
* **Response Thành công**:
  ```json
  {
    "success": true,
    "code": "SUCCESS",
    "data": {
      "id": "11111111-2222-3333-4444-555555555555",
      "email": "mentor1@rikai.technology",
      "fullName": "Tran Mentor",
      "dateOfBirth": "1995-05-15",
      "isActive": true,
      "role": {
        "roleName": "MENTOR",
        "description": "Người hướng dẫn"
      },
      "department": {
        "id": 1,
        "title": "Division 1"
      },
      "internCount": 5
    }
  }
  ```
* **Xử lý phía Flutter**:
  - Dùng `FutureBuilder` tải thông tin user khi mở tab **Profile**.
  - Hiển thị tên, email, tên phòng ban, số lượng thực tập sinh phụ trách.

---

### 1.3. Đăng xuất (Logout)
* **Phương thức**: `POST`
* **URL**: `/auth/logout`
* **Xử lý phía Flutter**:
  - Gọi API logout hoặc chỉ cần xóa token khỏi storage:
    ```dart
    await storage.delete(key: 'access_token');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    ```

---

## Giai Đoạn 2: Danh Mục Tĩnh / Dữ Liệu Đơn Giản (Master Data)

Mục tiêu học Flutter:
- Gọi API GET không có tham số phức tạp.
- Đổ dữ liệu vào các `DropdownButtonFormField` khi tạo/sửa Intern.
- Hiển thị danh sách dạng Card cơ bản.

---

### 2.1. Danh sách Phòng ban (Departments)
* **Phương thức**: `GET`
* **URL**: `/departments?page=0&limit=50`
* **Header**: `Authorization: Bearer <access_token>`
* **Response Mẫu**:
  ```json
  {
    "success": true,
    "code": "GET_ALL_DEPARTMENTS_SUCCESSFUL",
    "data": {
      "items": [
        {
          "id": 1,
          "title": "Division 1",
          "mentorCount": 6
        },
        {
          "id": 2,
          "title": "Division 2",
          "mentorCount": 4
        }
      ],
      "currentPage": 0,
      "totalPages": 1,
      "totalItems": 2,
      "pageSize": 50
    }
  }
  ```

---

### 2.2. Danh sách Vị trí thực tập (Positions)
* **Phương thức**: `GET`
* **URL**: `/positions?page=0&limit=50`
* **Header**: `Authorization: Bearer <access_token>`
* **Response Mẫu**:
  ```json
  {
    "success": true,
    "code": "GET_ALL_POSITIONS_SUCCESSFUL",
    "data": {
      "items": [
        {
          "id": 1,
          "title": "Flutter Developer",
          "internCount": 3
        },
        {
          "id": 2,
          "title": "Backend Java Developer",
          "internCount": 5
        },
        {
          "id": 3,
          "title": "Tester QA/QC",
          "internCount": 2
        }
      ],
      "currentPage": 0,
      "totalPages": 1,
      "totalItems": 3,
      "pageSize": 50
    }
  }
  ```

---

### 2.3. Danh sách Đợt thực tập (Internship Batches)
* **Phương thức**: `GET`
* **URL**: `/internship-batches?page=0&limit=20`
* **Header**: `Authorization: Bearer <access_token>`
* **Response Mẫu**:
  ```json
  {
    "success": true,
    "code": "GET_ALL_BATCHES_SUCCESSFUL",
    "data": {
      "items": [
        {
          "id": 1,
          "name": "Thực tập Sinh Mùa Xuân 2026",
          "startDate": "2026-03-01",
          "endDate": "2026-06-30",
          "status": "IN_PROGRESS",
          "internCount": 12
        }
      ],
      "currentPage": 0,
      "totalPages": 1,
      "totalItems": 1,
      "pageSize": 20
    }
  }
  ```

---

## Giai Đoạn 3: Tính Năng Cốt Lõi – Quản Lý Thực Tập Sinh (CRUD Interns)

Mục tiêu học Flutter:
- Xây dựng màn hình danh sách với `RefreshIndicator` (Pull-to-refresh) và thanh tìm kiếm (`TextField` search).
- Hiển thị badge trạng thái màu sắc theo `internStatus`:
  - `IN_PROGRESS`: Màu xanh dương / Cam
  - `PASSED`: Màu xanh lá
  - `FAILED`: Màu đỏ
- Truyền `id` khi click vào item để mở màn hình **Chi tiết Thực tập sinh**.
- Form thêm mới / cập nhật với date picker (`showDatePicker`).
- Xóa bản ghi có `showDialog` xác nhận.

---

### 3.1. Lấy danh sách thực tập sinh (Phân trang & Tìm kiếm)
* **Phương thức**: `GET`
* **URL**: `/interns` (hoặc `/interns/my-interns` nếu muốn lấy danh sách thuộc riêng Mentor đang login)
* **Query Parameters**:
  - `page`: Số trang (bắt đầu từ 0, mặc định 0)
  - `limit`: Số phần tử trên 1 trang (mặc định 10)
  - `keyword` *(tùy chọn)*: Từ khóa tìm theo họ tên
  - `status` *(tùy chọn)*: `IN_PROGRESS`, `COMPLETED`, `PASSED`, `FAILED`
  - `position_id` *(tùy chọn)*: Lọc theo vị trí
* **Header**: `Authorization: Bearer <access_token>`
* **Response Mẫu**:
  ```json
  {
    "success": true,
    "code": "GET_ALL_INTERNS_SUCCESSFUL",
    "data": {
      "items": [
        {
          "id": 101,
          "fullName": "Nguyen Van B",
          "position": {
            "id": 1,
            "title": "Flutter Developer"
          },
          "mentor": {
            "id": "11111111-2222-3333-4444-555555555555",
            "fullName": "Tran Mentor",
            "email": "mentor1@rikai.technology"
          },
          "internshipBatch": {
            "id": 1,
            "name": "Thực tập Sinh Mùa Xuân 2026"
          },
          "startDate": "2026-03-01",
          "endDate": "2026-06-01",
          "internStatus": "IN_PROGRESS"
        }
      ],
      "currentPage": 0,
      "totalPages": 3,
      "totalItems": 28,
      "pageSize": 10
    }
  }
  ```

---

### 3.2. Xem chi tiết thực tập sinh
* **Phương thức**: `GET`
* **URL**: `/interns/{id}` (Ví dụ: `/interns/101`)
* **Header**: `Authorization: Bearer <access_token>`
* **Response Mẫu**: Trả về 1 đối tượng `InternResponse` đầy đủ thông tin chi tiết.

---

### 3.3. Thêm mới thực tập sinh (Create)
* **Phương thức**: `POST`
* **URL**: `/interns`
* **Header**:
  ```http
  Authorization: Bearer <access_token>
  Content-Type: application/json
  ```
* **Request Body**:
  ```json
  {
    "fullName": "Le Thi Thu C",
    "positionId": 1,
    "mentorId": "11111111-2222-3333-4444-555555555555",
    "internshipBatchId": 1,
    "startDate": "2026-03-01",
    "endDate": "2026-06-01"
  }
  ```
* **Response**: Trả về `200 OK` hoặc `201 Created` kèm thông tin Intern vừa được tạo.

---

### 3.4. Cập nhật thông tin thực tập sinh (Update)
* **Phương thức**: `PUT`
* **URL**: `/interns/{id}` (Ví dụ: `/interns/101`)
* **Header**: `Authorization: Bearer <access_token>`
* **Request Body**:
  ```json
  {
    "fullName": "Nguyen Van B (Đã cập nhật)",
    "positionId": 1,
    "mentorId": "11111111-2222-3333-4444-555555555555",
    "internShipBatchId": 1,
    "startDate": "2026-03-01",
    "endDate": "2026-06-15",
    "internStatus": "PASSED"
  }
  ```

---

### 3.5. Xóa thực tập sinh (Delete)
* **Phương thức**: `DELETE`
* **URL**: `/interns/{id}` (Ví dụ: `/interns/101`)
* **Header**: `Authorization: Bearer <access_token>`
* **Response Thành công**:
  ```json
  {
    "success": true,
    "code": "DELETE_INTERN_SUCCESSFUL",
    "statusCode": 200,
    "message": "Xóa thực tập sinh thành công",
    "data": null
  }
  ```

---

## 4. Gợi Ý Cấu Trúc Thư Mục Cho Dự Án Flutter

Đối với người mới học Flutter, bạn nên tổ chức dự án theo mô hình tính năng (`feature-based` hoặc `simple clean architecture`):

```text
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart    // Chứa BASE_URL và endpoints
│   ├── network/
│   │   ├── api_client.dart       // Cấu hình http / dio, gắn Header Authorization
│   │   └── api_response.dart     // Model ApiResponse<T> & PageResponse<T>
│   └── storage/
│       └── token_storage.dart    // Đọc / Ghi token
├── models/
│   ├── user_model.dart
│   ├── intern_model.dart
│   ├── department_model.dart
│   └── position_model.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── interns/
│   │   ├── intern_list_screen.dart
│   │   ├── intern_detail_screen.dart
│   │   └── intern_form_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── main.dart
```

---

## 5. Các Thư Viện Khuyến Nghị Cho Flutter

Thêm các package sau vào file `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
    

  # Gọi API & Network
  dio: ^5.4.0                 # Hoặc gói http: ^1.2.0

  # Lưu trữ Access Token
  flutter_secure_storage: ^9.0.0

  # Format ngày tháng (Hiển thị dd/MM/yyyy)
  intl: ^0.19.0

  # Quản lý State đơn giản dễ học
  provider: ^6.1.2
```
