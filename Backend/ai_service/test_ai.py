import requests
import base64
import os
import glob

# Cấu hình
AI_SERVICE_URL = "http://localhost:8000"
# Tìm một ảnh bất kỳ trong thư mục uploads để test
UPLOAD_DIR = "../core_api/uploads/ekyc"

def test_ai_flow():
    # 1. Tìm ảnh mẫu (Ưu tiên ảnh SELFIE)
    image_files = glob.glob(os.path.join(UPLOAD_DIR, "SELFIE_*.*"))
    if not image_files:
        image_files = glob.glob(os.path.join(UPLOAD_DIR, "*.*"))
        
    if not image_files:
        print(f"[-] Không tìm thấy ảnh mẫu nào trong {UPLOAD_DIR}")
        return
    
    test_image_path = image_files[0]
    print(f"[*] Đang test với ảnh: {os.path.basename(test_image_path)}")

    # 2. Test API Extract Vector (/internal/ai/embed)
    print("\n[1] Đang gọi API Embed (Trích xuất vector)...")
    with open(test_image_path, "rb") as f:
        files = {"file": f}
        response = requests.post(f"{AI_SERVICE_URL}/internal/ai/embed", files=files)
    
    if response.status_code != 200:
        print(f"[-] Lỗi Embed: {response.text}")
        return
    
    vector = response.json()["vector"]
    print(f"[+] Đã lấy được vector ({len(vector)} chiều).")
    print(f"    5 giá trị đầu: {vector[:5]}")

    # 3. Test API Compare (/internal/ai/compare)
    # Chúng ta sẽ so sánh ảnh đó với chính nó để xem độ trùng khớp (phải là ~100%)
    print("\n[2] Đang gọi API Compare (So sánh khuôn mặt)...")
    with open(test_image_path, "rb") as f:
        img_base64 = base64.b64encode(f.read()).decode('utf-8')
    
    compare_data = {
        "storedVector": vector,
        "liveImageBase64": img_base64
    }
    
    response = requests.post(f"{AI_SERVICE_URL}/internal/ai/compare", json=compare_data)
    
    if response.status_code != 200:
        print(f"[-] Lỗi Compare: {response.text}")
        return
    
    result = response.json()
    print(f"[+] Kết quả so sánh:")
    print(f"    - Trùng khớp (isMatch): {result['isMatch']}")
    print(f"    - Độ tương đồng (similarity): {result['similarity']}")
    print(f"    - Khoảng cách (distance): {result['distance']}")
    print(f"    - Thông điệp: {result['message']}")

if __name__ == "__main__":
    # Đảm bảo đã cài requests: pip install requests
    try:
        test_ai_flow()
    except Exception as e:
        print(f"[-] Lỗi thực thi: {e}")
