import requests

BASE_URL = "http://127.0.0.1:9090/api/v1"

def check_pending_ekyc_api():
    # 1. Login as Admin
    print("--- Login as Admin ---")
    admin_login = {
        "username": "admin",
        "password": "123456"
    }
    try:
        admin_resp = requests.post(f"{BASE_URL}/auth/login", json=admin_login)
        admin_resp.raise_for_status()
        admin_token = admin_resp.json()['data']['accessToken']
        print("Login success.")

        # 2. Call Pending eKYC API
        print("\n--- Calling Pending eKYC API ---")
        headers = {'Authorization': f'Bearer {admin_token}'}
        resp = requests.get(f"{BASE_URL}/admin/ekyc/pending", headers=headers)
        print(f"Status Code: {resp.status_code}")
        print("Response Data:")
        import json
        print(json.dumps(resp.json(), indent=2, ensure_ascii=False))

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_pending_ekyc_api()
