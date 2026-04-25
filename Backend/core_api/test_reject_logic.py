import requests
import json
from datetime import datetime, date

BASE_URL = "http://127.0.0.1:9090/api/v1"

def run_reject_test():
    print("🚀 KIỂM THỬ CHỨC NĂNG TỪ CHỐI (REJECT) ĐƠN OT\n")

    try:
        # Login
        admin_res = requests.post(f"{BASE_URL}/auth/login", json={"username": "admin", "password": "123456"}).json()
        admin_token = admin_res['data']['accessToken']
        user_res = requests.post(f"{BASE_URL}/auth/login", json={"username": "nam.lh", "password": "123456"}).json()
        user_token = user_res['data']['accessToken']
        admin_headers = {"Authorization": f"Bearer {admin_token}"}
        user_headers = {"Authorization": f"Bearer {user_token}"}
    except Exception as e:
        print(f"❌ Lỗi login: {e}")
        return

    # 1. Tạo đơn mới
    print("1. Tạo đơn OT mới...")
    ot_payload = {
        "date": date.today().isoformat(),
        "startTime": "18:00:00",
        "endTime": "20:00:00",
        "reason": "Test Reject Logic"
    }
    ot_res = requests.post(f"{BASE_URL}/employee/overtime", json=ot_payload, headers=user_headers).json()
    ot_id = ot_res['data']['id']
    print(f"   ✅ Đã tạo đơn ID: {ot_id}")

    # 2. Thực hiện REJECT
    print(f"2. Admin thực hiện TỪ CHỐI (REJECTED) đơn {ot_id}...")
    review_res = requests.put(f"{BASE_URL}/admin/overtime/{ot_id}/review", 
                              params={"status": "REJECTED"},
                              headers=admin_headers).json()
    
    final_status = review_res['data']['status']
    print(f"   ✅ Kết quả trả về từ API: {final_status}")

    if final_status == "REJECTED":
        print("\n🎉 KẾT LUẬN: Logic REJECT hoạt động CHÍNH XÁC.")
    else:
        print(f"\n❌ LỖI: Kỳ vọng REJECTED nhưng kết quả lại là {final_status}")

if __name__ == "__main__":
    run_reject_test()
