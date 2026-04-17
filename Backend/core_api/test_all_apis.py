import requests
import json
import base64
import os
import time
from datetime import datetime, timedelta

# Configuration
CORE_API_URL = "http://localhost:8081/api/v1"
HEALTH_URL = "http://localhost:8081/health"

USER_CREDENTIALS = {
    "username": "anque",
    "password": "123456"
}

ADMIN_CREDENTIALS = {
    "username": "admin",
    "password": "123456"
}

def print_header(msg):
    print("\n" + "="*60)
    print(f" TESTING: {msg}")
    print("="*60)

class AllApiTester:
    def __init__(self):
        self.user_token = ""
        self.admin_token = ""
        self.qr_token = ""
        self.user_id = None
        self.user_employee_code = ""
        self.test_user_id = 1
        self.leave_id = None
        self.shift_id = None

    def check_health(self):
        print_header("System - Health Check")
        try:
            resp = requests.get(HEALTH_URL)
            print(f"Status: {resp.status_code}")
            print(f"Response: {resp.json()}")
            return resp.status_code == 200
        except Exception as e:
            print(f"[-] Health check failed: {e}")
            return False

    def login_user(self):
        print_header("Auth - User Login")
        resp = requests.post(f"{CORE_API_URL}/auth/login", json=USER_CREDENTIALS)
        if resp.status_code == 200:
            data = resp.json()['data']
            self.user_token = data['accessToken']
            self.user_id = data['user']['id']
            print(f"[+] User logged in. ID: {self.user_id}")
            return True
        print(f"[-] User login failed: {resp.text}")
        return False

    def login_admin(self):
        print_header("Auth - Admin Login")
        resp = requests.post(f"{CORE_API_URL}/auth/login", json=ADMIN_CREDENTIALS)
        if resp.status_code == 200:
            data = resp.json()['data']
            self.admin_token = data['accessToken']
            print(f"[+] Admin logged in.")
            return True
        print(f"[-] Admin login failed: {resp.text}")
        return False

    def test_ekyc(self):
        print_header("Auth - Register eKYC")
        headers = {"Authorization": f"Bearer {self.user_token}"}
        # Tạo ảnh giả lập
        with open("dummy_id.jpg", "wb") as f: f.write(b"fake image content")
        with open("dummy_selfie.jpg", "wb") as f: f.write(b"fake image content")
        
        files = {
            "id_card": ("id.jpg", open("dummy_id.jpg", "rb"), "image/jpeg"),
            "selfie": ("selfie.jpg", open("dummy_selfie.jpg", "rb"), "image/jpeg")
        }
        resp = requests.post(f"{CORE_API_URL}/auth/ekyc", headers=headers, files=files)
        print(f"Status: {resp.status_code}")
        print(f"Response: {resp.json().get('message')}")
        
        # Cleanup
        for f in files.values(): f[1].close()
        os.remove("dummy_id.jpg")
        os.remove("dummy_selfie.jpg")

    def test_qr(self):
        print_header("Auth - QR Code")
        headers = {"Authorization": f"Bearer {self.user_token}"}
        resp = requests.get(f"{CORE_API_URL}/auth/qr-code", headers=headers)
        if resp.status_code == 200:
            self.qr_token = resp.json()['data']['qrToken']
            print(f"[+] QR Token: {self.qr_token}")
            return True
        print(f"[-] QR Code failed: {resp.text}")
        return False

    def test_kiosk_resolve(self):
        print_header("Kiosk - Resolve QR")
        payload = {"qrToken": self.qr_token}
        resp = requests.post(f"{CORE_API_URL}/kiosk/resolve-qr", json=payload)
        if resp.status_code == 200:
            print(f"[+] Resolved user: {resp.json()['data']['fullName']}")
            return True
        print(f"[-] Resolve QR failed: {resp.text}")
        return False

    def test_kiosk_verify(self):
        print_header("Kiosk - Verify AI")
        # Sử dụng base64 giả lập
        payload = {
            "qrToken": self.qr_token,
            "liveImageBase64": "data:image/jpeg;base64,/9j/4AAQSkZJRg==" # Very short fake base64
        }
        resp = requests.post(f"{CORE_API_URL}/kiosk/verify", json=payload)
        print(f"Status: {resp.status_code}")
        # Sẽ lỗi AI nếu không có vector thực tế, nhưng check xem API có response không
        print(f"Response: {resp.json().get('message')}")

    def test_kiosk_live_logs(self):
        print_header("Kiosk - Live Logs")
        resp = requests.get(f"{CORE_API_URL}/kiosk/live-logs")
        if resp.status_code == 200:
            print(f"[+] Live logs count: {len(resp.json()['data'])}")
            return True
        return False

    def test_employee_attendance(self):
        print_header("Employee - Attendance History")
        headers = {"Authorization": f"Bearer {self.user_token}"}
        resp = requests.get(f"{CORE_API_URL}/employee/attendance", headers=headers)
        if resp.status_code == 200:
            print(f"[+] History count: {len(resp.json()['data'])}")
            return True
        return False

    def test_employee_leave(self):
        print_header("Employee - Submit Leave")
        headers = {"Authorization": f"Bearer {self.user_token}"}
        payload = {
            "fromDate": (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
            "toDate": (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%d"),
            "leaveType": "ANNUAL_LEAVE",
            "reason": "Family vacation"
        }
        resp = requests.post(f"{CORE_API_URL}/employee/leaves", headers=headers, json=payload)
        if resp.status_code == 200:
            self.leave_id = resp.json()['data']['id']
            print(f"[+] Leave request submitted. ID: {self.leave_id}")
            return True
        print(f"[-] Leave failed: {resp.text}")
        return False

    def test_admin_dashboard(self):
        print_header("Admin - Dashboard Stats")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        resp = requests.get(f"{CORE_API_URL}/admin/dashboard/stats", headers=headers)
        if resp.status_code == 200:
            print(f"[+] Stats: {resp.json()['data']}")
            return True
        return False

    def test_admin_users(self):
        print_header("Admin - User Management")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        # GET Users
        resp = requests.get(f"{CORE_API_URL}/admin/users", headers=headers)
        if resp.status_code == 200:
            users = resp.json()['data']
            print(f"[+] User list count: {len(users)}")
            for u in users:
                if u['id'] == self.user_id:
                    self.user_employee_code = u['employeeCode']
                    print(f"[+] Found current user employeeCode: {self.user_employee_code}")
        
        # POST User (Create new)
        new_username = f"testuser_{int(time.time())}"
        new_user = {
            "username": new_username,
            "password": "password123",
            "fullName": "Test User",
            "email": f"{new_username}@example.com",
            "phoneNumber": "0123456789",
            "employeeCode": f"EMP_{int(time.time())}",
            "role": "EMPLOYEE",
            "departmentId": 1
        }
        resp = requests.post(f"{CORE_API_URL}/admin/users", headers=headers, json=new_user)
        if resp.status_code == 201:
            self.test_user_id = resp.json()['data']['id']
            print(f"[+] Created test user ID: {self.test_user_id}")
        else:
            print(f"[-] Create user failed: {resp.status_code} - {resp.text}")

    def test_admin_ekyc_review(self):
        print_header("Admin - eKYC Review")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        # GET Pending
        resp = requests.get(f"{CORE_API_URL}/admin/ekyc/pending", headers=headers)
        if resp.status_code == 200:
            print(f"[+] Pending eKYC: {len(resp.json()['data'])}")
        
        # PUT Review
        payload = {"status": "APPROVED"}
        resp = requests.put(f"{CORE_API_URL}/admin/ekyc/{self.test_user_id}/review", headers=headers, json=payload)
        print(f"Status: {resp.status_code}")
        print(f"Response: {resp.json().get('message')}")

    def test_admin_leave_review(self):
        print_header("Admin - Leave Review")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        # GET All
        resp = requests.get(f"{CORE_API_URL}/admin/leaves", headers=headers)
        if resp.status_code == 200:
            print(f"[+] Total leaves: {len(resp.json()['data'])}")
        
        if self.leave_id:
            payload = {"status": "APPROVED", "remark": "Enjoy your trip"}
            resp = requests.put(f"{CORE_API_URL}/admin/leaves/{self.leave_id}/review", headers=headers, json=payload)
            print(f"Review Leave Status: {resp.status_code}")

    def test_admin_shifts(self):
        print_header("Admin - Shift Management")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        # GET All
        resp = requests.get(f"{CORE_API_URL}/admin/shifts", headers=headers)
        if resp.status_code == 200:
            print(f"[+] Total shifts: {len(resp.json()['data'])}")
        
        # POST New
        new_shift = {
            "shiftName": "Test Shift " + str(int(time.time())),
            "startTime": "09:00",
            "endTime": "18:00",
            "gracePeriod": 15
        }
        resp = requests.post(f"{CORE_API_URL}/admin/shifts", headers=headers, json=new_shift)
        if resp.status_code == 200:
            self.shift_id = resp.json()['data']['id']
            print(f"[+] Created shift ID: {self.shift_id}")

    def test_admin_attendance_adjust(self):
        print_header("Admin - Attendance Adjust")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        payload = {
            "employeeCode": self.user_employee_code,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "newCheckInTime": "08:00:00",
            "reason": "System adjustment test"
        }
        resp = requests.post(f"{CORE_API_URL}/admin/attendance/adjust", headers=headers, json=payload)
        if resp.status_code == 200:
            print(f"[+] Attendance adjusted successfully")
        else:
            print(f"[-] Adjust failed: {resp.status_code} - {resp.text}")

    def test_admin_reports(self):
        print_header("Admin - Reports Export")
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        today = datetime.now().strftime("%Y-%m-%d")
        resp = requests.get(f"{CORE_API_URL}/admin/reports/export?startDate={today}&endDate={today}", headers=headers)
        if resp.status_code == 200:
            print(f"[+] Report exported. Size: {len(resp.content)} bytes")
        else:
            print(f"[-] Report export failed: {resp.status_code}")

    def run_all(self):
        if not self.check_health(): return
        if not self.login_user(): return
        if not self.login_admin(): return
        
        self.test_ekyc()
        if self.test_qr():
            self.test_kiosk_resolve()
            self.test_kiosk_verify()
        
        self.test_kiosk_live_logs()
        self.test_employee_attendance()
        self.test_employee_leave()
        
        self.test_admin_dashboard()
        self.test_admin_users()
        self.test_admin_ekyc_review()
        self.test_admin_leave_review()
        self.test_admin_shifts()
        self.test_admin_attendance_adjust()
        self.test_admin_reports()

if __name__ == "__main__":
    tester = AllApiTester()
    tester.run_all()
