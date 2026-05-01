import cv2
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import io
import base64
import os

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

app = FastAPI(title="SmartOps AI Microservice v2")

# Chuyển sang VGG-Face: Rất ổn định với ảnh Webcam
MODEL_NAME = "VGG-Face"
# Sử dụng Cosine Similarity
DISTANCE_METRIC = "cosine"

class AiCompareRequest(BaseModel):
    storedVector: List[float]
    liveImageBase64: str

class EkycResponse(BaseModel):
    similarity: float
    isMatch: bool
    ocrData: Optional[dict] = None
    vector: Optional[List[float]] = None
    message: str = "Success"

@app.post("/internal/ai/embed")
async def extract_vector(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise HTTPException(status_code=400, detail="Không thể giải mã hình ảnh.")

        # Trích xuất vector
        results = DeepFace.represent(img_path=img, model_name=MODEL_NAME, enforce_detection=True)
        if not results:
            raise HTTPException(status_code=400, detail="Không tìm thấy khuôn mặt.")

        return {"vector": results[0]["embedding"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/internal/ai/routes")
async def list_routes():
    return [{"path": route.path, "name": route.name, "methods": route.methods} for route in app.routes]

@app.post("/internal/ai/verify-ekyc")
async def verify_ekyc(id_card: UploadFile = File(...), selfie: UploadFile = File(...)):
    print(">>> Received request for /internal/ai/verify-ekyc")
    try:
        # 1. Read images
        id_contents = await id_card.read()
        id_nparr = np.frombuffer(id_contents, np.uint8)
        id_img = cv2.imdecode(id_nparr, cv2.IMREAD_COLOR)

        selfie_contents = await selfie.read()
        selfie_nparr = np.frombuffer(selfie_contents, np.uint8)
        selfie_img = cv2.imdecode(selfie_nparr, cv2.IMREAD_COLOR)

        if id_img is None or selfie_img is None:
            raise HTTPException(status_code=400, detail="Không thể giải mã hình ảnh.")

        # 2. Face Matching (ID vs Selfie)
        try:
            result = DeepFace.verify(img1_path=id_img, img2_path=selfie_img, model_name=MODEL_NAME, distance_metric=DISTANCE_METRIC, enforce_detection=True)
            similarity = 1 - result["distance"]
            is_match = result["verified"]
        except Exception as face_e:
            print(f"Face matching error: {face_e}")
            similarity = 0.0
            is_match = False

        # 3. OCR (Temporarily Disabled)
        ocr_data = {
            "idNumber": "N/A",
            "fullName": "N/A",
            "message": "OCR feature is currently disabled"
        }

        return {
            "similarity": round(similarity, 4),
            "isMatch": is_match,
            "ocrData": ocr_data,
            "vector": DeepFace.represent(img_path=selfie_img, model_name=MODEL_NAME, enforce_detection=True)[0]["embedding"],
            "message": "Verify thành công" if is_match else "Khuôn mặt không khớp với CCCD"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/ai/compare")
async def compare_faces(request: AiCompareRequest):
    try:
        # 1. Giải mã ảnh Live
        header, encoded = request.liveImageBase64.split(",", 1) if "," in request.liveImageBase64 else ("", request.liveImageBase64)
        image_data = base64.b64decode(encoded)
        nparr = np.frombuffer(image_data, np.uint8)
        live_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if live_img is None:
            raise HTTPException(status_code=400, detail="Lỗi hình ảnh.")

        # 2. Tạo ảnh tạm từ vector gốc để dùng hàm verify của DeepFace (đảm bảo độ chính xác cao nhất)
        # Thay vì tính toán thủ công, ta để DeepFace tự handle normalization theo Model
        # Ở đây ta sẽ trích xuất vector của ảnh live và tính khoảng cách
        live_results = DeepFace.represent(img_path=live_img, model_name=MODEL_NAME, enforce_detection=True)
        if not live_results:
            raise HTTPException(status_code=400, detail="Không thấy mặt trong ảnh live.")
        
        live_vector = live_results[0]["embedding"]
        
        # 3. Tính toán độ tương đồng
        a = np.array(request.storedVector)
        b = np.array(live_vector)
        
        print(f">>> DEBUG: Stored Vector Len: {len(a)}, Live Vector Len: {len(b)}")
        
        if len(a) != len(b):
            return {
                "similarity": 0.0,
                "isMatch": False,
                "message": f"Lỗi: Kích thước vector không khớp ({len(a)} vs {len(b)}). Vui lòng eKYC lại."
            }

        cos_sim = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        
        # Nếu cos_sim là NaN hoặc cực nhỏ
        if np.isnan(cos_sim): cos_sim = 0.0
        
        similarity = float(cos_sim)
        print(f">>> DEBUG: Similarity calculated: {similarity}")
        is_match = bool(similarity >= 0.40) 

        return {
            "similarity": round(similarity, 4),
            "isMatch": is_match,
            "message": "Thành công" if is_match else f"Không khớp ({round(similarity*100, 1)}%)"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
