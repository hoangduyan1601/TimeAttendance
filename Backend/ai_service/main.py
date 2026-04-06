import cv2
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from typing import List
import io
import base64
import os

# Tắt bớt log của TensorFlow để đỡ rối
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

app = FastAPI(title="SmartOps AI Microservice (DeepFace Edition)")

# Chúng ta chọn mô hình Facenet để trả về vector 128 chiều như thiết kế
MODEL_NAME = "Facenet" 

class AiCompareRequest(BaseModel):
    storedVector: List[float]
    liveImageBase64: str

@app.post("/internal/ai/embed")
async def extract_vector(file: UploadFile = File(...)):
    """
    Nhận ảnh khuôn mặt, trả về mảng Vector số học (128 chiều).
    """
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Không thể giải mã hình ảnh.")

        # DeepFace.represent trả về list các khuôn mặt tìm thấy
        # Mỗi item chứa 'embedding' (vector)
        # Lưu ý: Lần đầu chạy nó sẽ tự tải model về (khoảng 100MB)
        results = DeepFace.represent(img_path=img, model_name=MODEL_NAME, enforce_detection=True)
        
        if not results:
            raise HTTPException(status_code=400, detail="Không tìm thấy khuôn mặt trong ảnh.")

        return {
            "vector": results[0]["embedding"]
        }
    except ValueError as ve:
        # Lỗi phổ biến: "Face could not be detected"
        raise HTTPException(status_code=400, detail=f"Lỗi nhận diện: {str(ve)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/ai/compare")
async def compare_faces(request: AiCompareRequest):
    """
    Nhận ảnh trực tiếp (Base64) và Vector gốc, trả về tỷ lệ trùng khớp (%).
    """
    try:
        # Giải mã Base64
        try:
            if "," in request.liveImageBase64:
                header, encoded = request.liveImageBase64.split(",", 1)
            else:
                encoded = request.liveImageBase64
            
            image_data = base64.b64decode(encoded)
            nparr = np.frombuffer(image_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Lỗi giải mã Base64: {str(e)}")
        
        if img is None:
            raise HTTPException(status_code=400, detail="Không thể giải mã hình ảnh từ Base64.")

        # Trích xuất vector của ảnh live
        live_results = DeepFace.represent(img_path=img, model_name=MODEL_NAME, enforce_detection=True)
        if not live_results:
            raise HTTPException(status_code=400, detail="Không tìm thấy khuôn mặt trong ảnh trực tiếp.")
            
        live_vector = live_results[0]["embedding"]

        # So sánh 2 vector bằng Numpy để tránh phụ thuộc Scipy nếu cần
        a = np.array(request.storedVector)
        b = np.array(live_vector)
        
        # Công thức tính Cosine Distance: 1 - Cosine Similarity
        cos_sim = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        cos_dist = 1.0 - cos_sim
        
        # Chuyển sang tỷ lệ tương đồng (0.0 - 1.0)
        similarity = cos_sim # Similarity chính là cos_sim
        
        # Ngưỡng (threshold) cho Facenet với Cosine distance thường là ~0.4 (similarity 0.6)
        is_match = bool(cos_dist <= 0.4)
        
        return {
            "similarity": round(float(similarity), 4),
            "distance": float(cos_dist),
            "isMatch": is_match,
            "message": "Xác thực thành công" if is_match else "Khuôn mặt không khớp"
        }
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=f"Lỗi nhận diện: {str(ve)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
