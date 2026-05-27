
import requests
import base64
import os
import time

# Configuration
CORE_API_URL = "http://localhost:9090/api/v1"
USER_CREDENTIALS = {"username": "anque", "password": "123456"}
ADMIN_CREDENTIALS = {"username": "admin", "password": "123456"}

def full_e2e_test():
    print("\n" + "="*60)
    print(" 🚀 FINAL E2E TEST: REGISTRATION -> APPROVAL -> CHECK-IN")
    print("="*60)

    # 1. Login User
    print("\n1. Đăng nhập nhân viên (anque)...")
    user_resp = requests.post(f"{CORE_API_URL}/auth/login", json=USER_CREDENTIALS).json()
    user_token = user_resp['data']['accessToken']
    user_id = user_resp['data']['user']['id']
    headers = {"Authorization": f"Bearer {user_token}"}

    # 2. Register eKYC with a real image
    print("2. Đăng ký eKYC (Upload ảnh chân dung thực tế)...")
    # Chúng ta dùng image.png có sẵn trong Documents làm cả CCCD và Selfie để đảm bảo khớp 100%
    with open('Documents/image.png', 'rb') as f:
        img_data = f.read()
    
    files = {
        "idCard": ("id.png", img_data, "image/png"),
        "selfie": ("selfie.png", img_data, "image/png")
    }
    ekyc_resp = requests.post(f"{CORE_API_URL}/employee/ekyc", headers=headers, files=files).json()
    print(f"   [+] Kết quả eKYC: {ekyc_resp['message']}")

    # 3. Admin Login & Approval
    print("\n3. Admin đăng nhập và phê duyệt eKYC...")
    admin_resp = requests.post(f"{CORE_API_URL}/auth/login", json=ADMIN_CREDENTIALS).json()
    admin_token = admin_resp['data']['accessToken']
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    approve_resp = requests.put(f"{CORE_API_URL}/admin/ekyc/{user_id}/review", 
                                headers=admin_headers, json={"status": "APPROVED"}).json()
    print(f"   [+] Trạng thái phê duyệt: {approve_resp['message']}")

    # 4. Generate QR Code
    print("\n4. Nhân viên lấy mã QR mới...")
    qr_resp = requests.get(f"{CORE_API_URL}/auth/qr-code", headers=headers).json()
    qr_token = qr_resp['data']['qrToken']

    # 5. Kiosk Check-in (Simulate Live Camera with the same image)
    print("5. Kiosk thực hiện Chấm công (QR + Face Matching)...")
    with open('image_base64.txt', 'r') as f:
        img_base64 = f.read().strip()
    
    # Thêm tiền tố data:image/png;base64, nếu cần
    if not img_base64.startswith("data:"):
        img_base64 = "data:image/png;base64," + img_base64

    checkin_payload = {
        "qrToken": qr_token,
        "liveImageBase64": img_base64,
        "kioskId": "KIOSK-GATE-01"
    }
    
    # Đợi 1 chút để DB cập nhật status
    time.sleep(1)
    
    checkin_resp = requests.post(f"{CORE_API_URL}/kiosk/verify", json=checkin_payload).json()
    
    if checkin_resp['status'] == 'success':
        print(f"\n✅ THÀNH CÔNG 100%!")
        print(f"   Nhân viên: {checkin_resp['data']['employeeName']}")
        print(f"   Thời gian: {checkin_resp['data']['time']}")
        print(f"   Trạng thái: {checkin_resp['data']['attendanceStatus']}")
        print(f"   Độ khớp AI: {round(checkin_resp['data']['similarityScore'] * 100, 2)}%")
    else:
        print(f"\n❌ THẤT BẠI!")
        print(f"   Lỗi: {checkin_resp['message']}")

if __name__ == "__main__":
    full_e2e_test()
