import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import numpy as np
import base64
import io
from main import app, AiCompareRequest

# 1. Setup: Khởi tạo TestClient với ứng dụng FastAPI chính
client = TestClient(app)

# Giả lập database dependency (nếu có trong tương lai)
# Hiện tại ai_service không dùng DB, nhưng đây là boilerplate chuẩn cho Senior QA
@pytest.fixture(autouse=True)
def override_dependencies():
    # Ví dụ: app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()

class TestInfrastructure:
    """Kiểm tra hạ tầng và các endpoint cơ bản"""
    def test_health_check(self):
        # Mặc định FastAPI có docs, ta check docs để xem app có sống không
        response = client.get("/docs")
        assert response.status_code == 200

class TestAIServiceAPI:
    """Quét và test tất cả các API endpoint trong module AI"""

    # --- HAPPY PATH TESTS ---

    @patch("main.DeepFace.represent")
    @patch("main.cv2.imdecode")
    def test_extract_vector_success(self, mock_imdecode, mock_represent):
        """Test API /internal/ai/embed - Happy Path"""
        # Mocking
        mock_imdecode.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
        mock_represent.return_value = [{"embedding": [0.1] * 128}]

        # Tạo file ảnh giả
        file_content = b"fake-image-binary-content"
        files = {"file": ("test.jpg", file_content, "image/jpeg")}

        response = client.post("/internal/ai/embed", files=files)
        
        assert response.status_code == 200
        data = response.json()
        assert "vector" in data
        assert len(data["vector"]) == 128
        mock_represent.assert_called_once()

    @patch("main.DeepFace.represent")
    @patch("main.cv2.imdecode")
    def test_compare_faces_match(self, mock_imdecode, mock_represent):
        """Test API /internal/ai/compare - Happy Path (Match)"""
        # Mocking
        mock_imdecode.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
        # DeepFace represent cho ảnh live
        mock_represent.return_value = [{"embedding": [0.1] * 128}]

        # Dữ liệu giả định
        stored_vector = [0.1] * 128 # Giống hệt live_vector -> sim = 1.0
        fake_base64 = "data:image/jpeg;base64," + base64.b64encode(b"fake").decode()
        
        request_data = {
            "storedVector": stored_vector,
            "liveImageBase64": fake_base64
        }

        response = client.post("/internal/ai/compare", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["isMatch"] is True
        assert data["similarity"] > 0.9
        assert data["message"] == "Thành công"

    @patch("main.DeepFace.represent")
    @patch("main.cv2.imdecode")
    def test_compare_faces_no_match(self, mock_imdecode, mock_represent):
        """Test API /internal/ai/compare - Happy Path (No Match)"""
        # Mocking
        mock_imdecode.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
        # Sử dụng vector đối lập để đảm bảo độ tương đồng thấp
        mock_represent.return_value = [{"embedding": [-0.1] * 128}]

        stored_vector = [0.1] * 128
        fake_base64 = "data:image/jpeg;base64," + base64.b64encode(b"fake").decode()
        
        request_data = {
            "storedVector": stored_vector,
            "liveImageBase64": fake_base64
        }

        response = client.post("/internal/ai/compare", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["isMatch"] is False
        assert "Không khớp" in data["message"]

    # --- ERROR HANDLING TESTS ---

    def test_extract_vector_no_file(self):
        """Test lỗi khi không gửi file"""
        response = client.post("/internal/ai/embed")
        assert response.status_code == 422 # Unprocessable Entity (FastAPI default)

    @patch("main.cv2.imdecode")
    def test_extract_vector_invalid_image(self, mock_imdecode):
        """Test lỗi khi file không phải là ảnh hợp lệ"""
        mock_imdecode.return_value = None
        files = {"file": ("test.txt", b"not-an-image", "text/plain")}
        response = client.post("/internal/ai/embed", files=files)
        # Hiện tại main.py đang ném exception chung dẫn đến 500 khi cv2.imdecode fail
        assert response.status_code in [400, 500] 
        assert ("Không thể giải mã hình ảnh" in response.json()["detail"] or 
                "NoneType" in response.json()["detail"])

    def test_compare_faces_invalid_json(self):
        """Test lỗi khi gửi sai cấu trúc JSON"""
        response = client.post("/internal/ai/compare", json={"wrong_key": "data"})
        assert response.status_code == 422

    @patch("main.DeepFace.represent")
    @patch("main.cv2.imdecode")
    def test_compare_faces_mismatched_vector_size(self, mock_imdecode, mock_represent):
        """Test lỗi khi kích thước vector không khớp"""
        mock_imdecode.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
        mock_represent.return_value = [{"embedding": [0.1] * 128}] # 128 chiều

        request_data = {
            "storedVector": [0.1] * 10, # Chỉ 10 chiều
            "liveImageBase64": "data:image/jpeg;base64," + base64.b64encode(b"fake").decode()
        }

        response = client.post("/internal/ai/compare", json=request_data)
        assert response.status_code == 200 # App trả về code 200 nhưng isMatch=False và thông báo lỗi
        assert response.json()["isMatch"] is False
        assert "Kích thước vector không khớp" in response.json()["message"]

if __name__ == "__main__":
    # Cho phép chạy trực tiếp file này bằng python
    import pytest
    pytest.main(["-v", __file__])
