import requests
import json
from datetime import datetime, date

BASE_URL = "http://127.0.0.1:9090/api/v1"

def run_test():
    print("🚀 BẮT ĐẦU KIỂM THỬ TOÀN DIỆN HỆ THỐNG OT & CẢNH BÁO\n")

    # --- BƯỚC 1: ĐĂNG NHẬP ---
    print("1. Đang đăng nhập hệ thống...")
    try:
        # Admin Login
        admin_res = requests.post(f"{BASE_URL}/auth/login", json={"username": "admin", "password": "123456"}).json()
        admin_token = admin_res['data']['accessToken']
        
        # Employee Login (Lê Hoàng Nam)
        user_res = requests.post(f"{BASE_URL}/auth/login", json={"username": "nam.lh", "password": "123456"}).json()
        user_token = user_res['data']['accessToken']
        print("   ✅ Đăng nhập thành công (Admin & Nhân viên)\n")
    except Exception as e:
        print(f"   ❌ Lỗi kết nối Server: {e}. Hãy đảm bảo Backend đang chạy tại port 9090!")
        return

    # --- BƯỚC 2: TẠO ĐƠN OT ---
    print("2. Nhân viên [nam.lh] đang tạo đơn OT cho hôm nay...")
    ot_payload = {
        "date": date.today().isoformat(),
        "startTime": "17:30:00",
        "endTime": "21:00:00",
        "reason": "Kiểm thử chức năng tạo đơn mới"
    }
    try:
        ot_res = requests.post(f"{BASE_URL}/employee/overtime", json=ot_payload, 
                               headers={"Authorization": f"Bearer {user_token}"}).json()
        new_ot_id = ot_res['data']['id']
        print(f"   ✅ Tạo đơn thành công! OT_ID: {new_ot_id}, Trạng thái: {ot_res['data']['status']}\n")
    except Exception as e:
        print(f"   ❌ Lỗi khi tạo đơn: {e}")
        return

    # --- BƯỚC 3: DUYỆT ĐƠN OT ---
    print("3. Admin đang duyệt đơn OT vừa tạo...")
    try:
        review_res = requests.put(f"{BASE_URL}/admin/overtime/{new_ot_id}/review", 
                                  params={"status": "APPROVED"},
                                  headers={"Authorization": f"Bearer {admin_token}"}).json()
        print(f"   ✅ Duyệt thành công! Trạng thái mới: {review_res['data']['status']}\n")
    except Exception as e:
        print(f"   ❌ Lỗi khi duyệt đơn: {e}")
        return

    # --- BƯỚC 4: KIỂM TRA THÔNG BÁO CẢNH BÁO ---
    print("4. Kiểm tra danh sách thông báo (Cảnh báo quá giờ)...")
    try:
        noti_res = requests.get(f"{BASE_URL}/admin/notifications", 
                                headers={"Authorization": f"Bearer {admin_token}"}).json()
        
        notifications = noti_res['data']
        # Tìm thông báo ALERT hoặc thông báo liên quan đến OT
        alerts = [n for n in notifications if n['type'] == 'ALERT' or "quá giờ" in n['title'].lower()]
        
        if alerts:
            print(f"   ✅ Tìm thấy {len(alerts)} cảnh báo ALERT trong hệ thống!")
            print(f"   🔔 Thông báo mới nhất: {alerts[0]['message']}")
        else:
            print("   ❓ Hiện tại chưa có cảnh báo quá giờ mới sinh ra.")
    except Exception as e:
        print(f"   ❌ Lỗi khi lấy thông báo: {e}")

    print("\n🏁 KẾT THÚC KIỂM THỬ.")

if __name__ == "__main__":
    run_test()
