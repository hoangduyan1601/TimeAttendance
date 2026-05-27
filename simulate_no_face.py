
import requests
import base64

# Configuration
CORE_API_URL = "http://localhost:9090/api/v1"
USER_CREDENTIALS = {"username": "anque", "password": "123456"}

def simulate_no_face():
    print("\n" + "="*60)
    print(" SIMULATION: FACE NOT DETECTED")
    print("="*60)

    # 1. Login to get token
    resp = requests.post(f"{CORE_API_URL}/auth/login", json=USER_CREDENTIALS)
    token = resp.json()['data']['accessToken']
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get QR Code
    resp = requests.get(f"{CORE_API_URL}/auth/qr-code", headers=headers)
    qr_token = resp.json()['data']['qrToken']

    # 3. Prepare a "No-Face" Image (A simple blue square)
    # This is a base64 of a 100x100 blue JPEG
    no_face_image = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCADIAcgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSEUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqGhcXl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5/ooooAKKKKACKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//9k="

    # 4. Call Kiosk Verify
    print("\n[+] Đang gửi ảnh không có khuôn mặt tới Kiosk...")
    payload = {
        "qrToken": qr_token,
        "liveImageBase64": no_face_image
    }
    
    # Kiosk endpoints usually don't require Auth header if using QR token, 
    # but the implementation might vary. In this project, it seems public.
    resp = requests.post(f"{CORE_API_URL}/kiosk/verify", json=payload)
    
    print(f"Mã phản hồi (HTTP Status): {resp.status_code}")
    try:
        data = resp.json()
        print(f"Thông báo từ hệ thống: {data.get('message')}")
        if data.get('status') == 'error':
             print("✅ Kết quả: Hệ thống đã chặn thành công và đưa ra cảnh báo.")
    except:
        print(f"[-] Lỗi phản hồi: {resp.text}")

if __name__ == "__main__":
    simulate_no_face()
