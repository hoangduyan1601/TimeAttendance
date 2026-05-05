import requests
import sys

BASE_URL = "http://127.0.0.1:9090/api/v1"

def test_ekyc_notification_flow():
    # 1. Login to get token (using a known employee from seed data: nam.lh)
    print("--- Step 1: Login ---")
    login_payload = {
        "username": "nam.lh",
        "password": "123456"
    }
    try:
        login_resp = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
        login_resp.raise_for_status()
        token = login_resp.json()['data']['accessToken']
        user_id = login_resp.json()['data']['user']['id']
        print(f"Login successful. User ID: {user_id}")
    except Exception as e:
        print(f"Login failed: {e}")
        return

    # 2. Mock images (small transparent pixels)
    print("\n--- Step 2: Register eKYC ---")
    pixel = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n\x2e\x4e\x00\x00\x00\x00IEND\xaeB`\x82'
    files = {
        'selfie': ('selfie.png', pixel, 'image/png')
    }
    headers = {
        'Authorization': f'Bearer {token}'
    }

    try:
        # Note: This will likely fail AI verification (pixel image)
        # But our goal is to see if it triggers the service logic in the logs or DB
        print("Sending eKYC request...")
        ekyc_resp = requests.post(f"{BASE_URL}/employee/ekyc", files=files, headers=headers)
        print(f"Status: {ekyc_resp.status_code}")
        print(f"Response: {ekyc_resp.text}")
    except Exception as e:
        print(f"eKYC request failed: {e}")

    # 3. Login as Admin to check notifications
    print("\n--- Step 3: Check Admin Notifications ---")
    admin_login = {
        "username": "admin",
        "password": "123456"
    }
    try:
        admin_resp = requests.post(f"{BASE_URL}/auth/login", json=admin_login)
        admin_token = admin_resp.json()['data']['accessToken']
        
        notif_headers = {'Authorization': f'Bearer {admin_token}'}
        notif_resp = requests.get(f"{BASE_URL}/admin/notifications", headers=notif_headers)
        notifications = notif_resp.json()['data']
        
        print(f"Found {len(notifications)} notifications.")
        for n in notifications[:5]:
            print(f"- [{n['type']}] {n['title']}: {n['message']}")
            
    except Exception as e:
        print(f"Admin check failed: {e}")

if __name__ == "__main__":
    test_ekyc_notification_flow()
