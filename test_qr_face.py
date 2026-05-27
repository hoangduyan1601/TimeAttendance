
import requests
import json
import base64
from datetime import datetime

# Configuration
CORE_API_URL = "http://localhost:9090/api/v1"

USER_CREDENTIALS = {
    "username": "anque",
    "password": "123456"
}

def test_qr_and_face_matching():
    print("\n" + "="*60)
    print(" TESTING: QR + FACE MATCHING FLOW")
    print("="*60)

    # 1. Login
    print("\n1. Đang đăng nhập...")
    resp = requests.post(f"{CORE_API_URL}/auth/login", json=USER_CREDENTIALS)
    if resp.status_code != 200:
        print(f"[-] Login failed: {resp.text}")
        return
    
    token = resp.json()['data']['accessToken']
    user_name = resp.json()['data']['user']['fullName']
    print(f"[+] Đăng nhập thành công: {user_name}")

    # 2. Get QR Code
    print("\n2. Đang lấy mã QR...")
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{CORE_API_URL}/auth/qr-code", headers=headers)
    if resp.status_code != 200:
        print(f"[-] QR Code failed: {resp.text}")
        return
    
    qr_token = resp.json()['data']['qrToken']
    print(f"[+] QR Token: {qr_token[:20]}...")

    # 3. Kiosk Resolve QR (Step 1 in Kiosk UI)
    print("\n3. Kiosk: Giải mã QR...")
    payload = {"qrToken": qr_token}
    resp = requests.post(f"{CORE_API_URL}/kiosk/resolve-qr", json=payload)
    if resp.status_code != 200:
        print(f"[-] Resolve QR failed: {resp.text}")
        return
    
    resolved_name = resp.json()['data']['fullName']
    print(f"[+] Kiosk đã nhận diện: {resolved_name}")

    # 4. Kiosk Verify (Step 2 in Kiosk UI - Face Matching)
    print("\n4. Kiosk: Xác thực khuôn mặt (Face Matching)...")
    # Sử dụng một base64 hợp lệ nhưng có thể không có mặt thực tế 
    # (Để xem hệ thống phản hồi thế nào: Thất bại nhận diện hay Gian lận)
    fake_image = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSEUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqGhcXl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oADAMBAAIRAxEAPwA8D//Z"
    
    verify_payload = {
        "qrToken": qr_token,
        "liveImageBase64": fake_image
    }
    
    resp = requests.post(f"{CORE_API_URL}/kiosk/verify", json=verify_payload)
    print(f"Status: {resp.status_code}")
    
    try:
        data = resp.json()
        print(f"Kết quả từ hệ thống: {data.get('message')}")
        if resp.status_code == 200:
            print(f"[+] Trạng thái chấm công: {data['data'].get('attendanceStatus')}")
        else:
            print(f"[-] Chi tiết lỗi: {data.get('message')}")
    except:
        print(f"[-] Response không phải JSON: {resp.text}")

if __name__ == "__main__":
    test_qr_and_face_matching()
