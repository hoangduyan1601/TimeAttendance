import requests
import json
import base64
import os
import time

# Cấu hình URL
CORE_API_URL = "http://localhost:8081/api/v1"

# Thông tin đăng nhập của bạn
USER_CREDENTIALS = {
    "username": "anhdv",
    "password": "password123"
}

ADMIN_CREDENTIALS = {
    "username": "admin",
    "password": "123456"
}

def print_header(msg):
    print("\n" + "="*50)
    print(f" TESTING: {msg}")
    print("="*50)

class BackendTester:
    def __init__(self):
        self.token = ""
        self.admin_token = ""
        self.qr_token = ""

    def login(self):
        print_header("Auth - Login")
        try:
            response = requests.post(f"{CORE_API_URL}/auth/login", json=USER_CREDENTIALS)
            print(f"Status: {response.status_code}")
            json_data = response.json()
            
            if response.status_code == 200:
                # Lưu ý: Java dùng accessToken (CamelCase)
                self.token = json_data['data']['accessToken']
                print(f"[+] Đăng nhập thành công. Token: {self.token[:20]}...")
                return True
            else:
                print(f"[-] Đăng nhập thất bại: {json_data.get('message', 'Unknown error')}")
                return False
        except Exception as e:
            print(f"[-] Lỗi kết nối: {e}")
            return False

    def test_ekyc(self):
        print_header("Auth - Register eKYC")
        # Sử dụng một ảnh thực tế từ thư mục uploads để AI nhận diện được
        UPLOAD_DIR = "uploads/ekyc"
        import glob
        image_files = glob.glob(os.path.join(UPLOAD_DIR, "SELFIE_*.*"))
        
        if not image_files:
            print("[-] Không tìm thấy ảnh SELFIE mẫu để test eKYC.")
            return

        test_img = image_files[0]
        print(f"[*] Sử dụng ảnh: {test_img}")

        headers = {"Authorization": f"Bearer {self.token}"}
        with open(test_img, "rb") as f1, open(test_img, "rb") as f2:
            files = {
                "id_card": (os.path.basename(test_img), f1, "image/jpeg"),
                "selfie": (os.path.basename(test_img), f2, "image/jpeg")
            }
            response = requests.post(f"{CORE_API_URL}/auth/ekyc", headers=headers, files=files)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.json().get('message', '')}")

    def test_get_qr(self):
        print_header("Auth - Generate Dynamic QR")
        headers = {"Authorization": f"Bearer {self.token}"}
        response = requests.get(f"{CORE_API_URL}/auth/qr-code", headers=headers)
        if response.status_code == 200:
            self.qr_token = response.json()['data']['qrToken']
            print(f"[+] QR Token sinh ra: {self.qr_token}")
            return True
        print(f"[-] Thất bại: {response.text}")
        return False

    def test_kiosk_verify(self):
        print_header("Kiosk - Verify Attendance")
        # Giả lập ảnh live (lấy base64 từ ảnh có sẵn để AI so sánh khớp)
        UPLOAD_DIR = "uploads/ekyc"
        import glob
        image_files = glob.glob(os.path.join(UPLOAD_DIR, "SELFIE_*.*"))
        if not image_files: return

        with open(image_files[0], "rb") as f:
            live_img_base64 = base64.b64encode(f.read()).decode('utf-8')

        payload = {
            "kioskId": "KIOSK_GATE_01",
            "qrToken": self.qr_token,
            "liveImageBase64": live_img_base64
        }

        response = requests.post(f"{CORE_API_URL}/kiosk/verify", json=payload)

        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()['data']
            print(f"[+] Chấm công thành công cho: {data['employeeName']}")
            print(f"    Trạng thái: {data['attendanceStatus']}")
            print(f"    Độ tương đồng: {data['similarityScore']}")
        else:
            print(f"[-] Xác thực thất bại: {response.json().get('message', '')}")

    def test_admin_dashboard(self):
        print_header("Admin - Get Dashboard Stats")
        resp = requests.post(f"{CORE_API_URL}/auth/login", json=ADMIN_CREDENTIALS)
        if resp.status_code == 200:
            admin_token = resp.json()['data']['accessToken']
            headers = {"Authorization": f"Bearer {admin_token}"}
            response = requests.get(f"{CORE_API_URL}/admin/dashboard/stats", headers=headers)
            if response.status_code == 200:
                stats = response.json()['data']
                print(f"[+] Thống kê ngày hôm nay:")
                print(json.dumps(stats, indent=4))
        else:
            print("[-] Admin login failed")

if __name__ == "__main__":
    tester = BackendTester()
    if tester.login():
        tester.test_ekyc()
        if tester.test_get_qr():
            tester.test_kiosk_verify()
        tester.test_admin_dashboard()
