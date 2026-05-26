import cv2
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Literal
import io
import base64
import os
import mediapipe as mp
import traceback
import sys

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

app = FastAPI(title="SmartOps AI Microservice v2")

# Chuyển sang VGG-Face: Rất ổn định với ảnh Webcam
MODEL_NAME = "VGG-Face"
# Sử dụng Cosine Similarity
DISTANCE_METRIC = "cosine"

def _log(msg: str):
    """
    Windows terminals may use non-UTF encodings (cp1252), causing UnicodeEncodeError.
    Always write UTF-8 bytes with safe escaping.
    """
    try:
        sys.stderr.buffer.write((msg + "\n").encode("utf-8", errors="backslashreplace"))
        sys.stderr.flush()
    except Exception:
        # As a last resort, drop logging
        pass

class AiCompareRequest(BaseModel):
    storedVector: List[float]
    liveImageBase64: str

class AiCompareChallengeRequest(BaseModel):
    storedVector: List[float]
    framesBase64: List[str]
    challengeType: Literal["TURN_LEFT", "TURN_RIGHT", "BLINK"]

class EkycResponse(BaseModel):
    similarity: float
    isMatch: bool
    ocrData: Optional[dict] = None
    vector: Optional[List[float]] = None
    message: str = "Success"

def check_liveness(img):
    """
    Kiểm tra tính sống thực cơ bản của ảnh.
    Sử dụng Laplacian variance để phát hiện ảnh mờ (thường là ảnh chụp qua màn hình hoặc giấy in).
    """
    gray = cv2.cvtColor(img, cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img)
    variance = cv2.Laplacian(gray, cv2.CV_64F).var()
    # Ngưỡng variance thấp: điều chỉnh xuống 70 để ổn định hơn trên webcam
    return bool(variance > 70), float(variance)

if not hasattr(mp, "solutions"):
    # Newer mediapipe versions (e.g., 0.10.35) remove mp.solutions.*.
    # This service uses the classic FaceMesh API, so we need a compatible version.
    raise RuntimeError(
        "MediaPipe API incompatible: missing mp.solutions. "
        "Please install mediapipe==0.10.14 (see requirements.txt)."
    )

_mp_face_mesh = mp.solutions.face_mesh.FaceMesh(
    static_image_mode=True,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
)

def _extract_face_landmarks(img_bgr):
    # mediapipe expects RGB
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    results = _mp_face_mesh.process(img_rgb)
    if not results.multi_face_landmarks:
        return None
    return results.multi_face_landmarks[0].landmark

def _eye_aspect_ratio(landmarks, w, h, left=True):
    # Indices from MediaPipe FaceMesh (approx): left eye [33,160,158,133,153,144], right eye [362,385,387,263,373,380]
    if left:
        p1, p2, p3, p4, p5, p6 = 33, 160, 158, 133, 153, 144
    else:
        p1, p2, p3, p4, p5, p6 = 362, 385, 387, 263, 373, 380

    def pt(i):
        lm = landmarks[i]
        return np.array([lm.x * w, lm.y * h], dtype=np.float32)

    A = np.linalg.norm(pt(p2) - pt(p6))
    B = np.linalg.norm(pt(p3) - pt(p5))
    C = np.linalg.norm(pt(p1) - pt(p4))
    if C == 0:
        return 0.0
    return float((A + B) / (2.0 * C))

def _head_turn_score(landmarks, w, h):
    # Use nose tip vs face width: nose_x relative shift from midpoint.
    # Nose tip index 1; left cheek-ish 234; right cheek-ish 454
    nose = landmarks[1]
    left = landmarks[234]
    right = landmarks[454]
    nose_x = nose.x
    mid_x = (left.x + right.x) / 2.0
    face_w = abs(right.x - left.x)
    if face_w < 1e-6:
        return 0.0
    # positive means nose moved to right (person turned left typically)
    return float((nose_x - mid_x) / face_w)

def _challenge_satisfied(challenge_type, landmarks, w, h):
    if landmarks is None:
        return False, 0.0

    if challenge_type in ("TURN_LEFT", "TURN_RIGHT"):
        score = _head_turn_score(landmarks, w, h)
        # Heuristic thresholds
        if challenge_type == "TURN_LEFT":
            return score > 0.12, score
        return score < -0.12, score

    if challenge_type == "BLINK":
        left_ear = _eye_aspect_ratio(landmarks, w, h, left=True)
        right_ear = _eye_aspect_ratio(landmarks, w, h, left=False)
        ear = (left_ear + right_ear) / 2.0
        # Blink: EAR drops significantly
        return ear < 0.18, ear

    return False, 0.0

@app.post("/internal/ai/embed")
async def extract_vector(file: UploadFile = File(...)):
    try:
        _log(f"[AI] /embed request received. file={file.filename}")
        contents = await file.read()
        if not contents:
             raise HTTPException(status_code=400, detail="Nội dung file rỗng.")

        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            _log("[AI] /embed error: cannot decode image")
            raise HTTPException(status_code=400, detail="Không thể giải mã hình ảnh.")

        # Check Liveness
        is_live, score = check_liveness(img)
        if not is_live:
             _log(f"[AI] /embed liveness warning: score={score}")

        # Trích xuất vector (Tắt enforce_detection để tránh lỗi 400 nếu ảnh hơi mờ)
        results = DeepFace.represent(img_path=img, model_name=MODEL_NAME, enforce_detection=False)
        if not results or len(results) == 0:
            raise HTTPException(status_code=400, detail="AI không tìm thấy khuôn mặt trong ảnh. Vui lòng chụp lại rõ hơn.")

        return {
            "vector": results[0]["embedding"],
            "liveness_score": round(float(score), 2),
            "is_potentially_live": bool(is_live)
        }
    except BaseException as e:
        # Some underlying libs may throw ExceptionGroup/BaseException; expose detail for debugging.
        err = traceback.format_exc()
        _log("[AI] /embed exception:\n" + err)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/internal/ai/routes")
async def list_routes():
    return [{"path": route.path, "name": route.name, "methods": route.methods} for route in app.routes]

@app.post("/internal/ai/verify-ekyc")
async def verify_ekyc(id_card: UploadFile = File(...), selfie: UploadFile = File(...)):
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

        # 2. Check Liveness
        is_live, liveness_score = check_liveness(live_img)
        if not is_live or liveness_score < 80:
             return {
                "similarity": 0.0,
                "isMatch": False,
                "isLive": False,
                "livenessScore": round(liveness_score, 2),
                "message": "Phát hiện gian lận! Vui lòng đứng trước camera."
            }

        # 3. Trích xuất vector và so khớp
        live_results = DeepFace.represent(img_path=live_img, model_name=MODEL_NAME, enforce_detection=True)
        if not live_results:
            raise HTTPException(status_code=400, detail="Không thấy mặt trong ảnh live.")
        
        live_vector = live_results[0]["embedding"]
        
        a = np.array(request.storedVector)
        b = np.array(live_vector)
        
        if len(a) != len(b):
            return {
                "similarity": 0.0,
                "isMatch": False,
                "isLive": True,
                "message": "Lỗi: Vector không khớp. Cần eKYC lại."
            }

        cos_sim = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        similarity = float(cos_sim) if not np.isnan(cos_sim) else 0.0
        
        is_match = bool(similarity >= 0.40) 

        return {
            "similarity": round(similarity, 4),
            "isMatch": is_match,
            "isLive": True,
            "livenessScore": round(liveness_score, 2),
            "message": "Thành công" if is_match else f"Khuôn mặt không khớp ({round(similarity*100, 1)}%)"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/internal/ai/compare-challenge")
async def compare_faces_challenge(request: AiCompareChallengeRequest):
    """
    Challenge–response anti-spoof:
    - Verify requested action across multiple frames (TURN_LEFT/ TURN_RIGHT/ BLINK)
    - Apply basic liveness (sharpness) check
    - Pick best frame to compare embedding with stored vector (cosine similarity)
    """
    try:
        if not request.framesBase64 or len(request.framesBase64) < 3:
            raise HTTPException(status_code=400, detail="Thiếu dữ liệu camera (framesBase64).")

        best = {
            "similarity": 0.0,
            "frame_idx": -1,
            "liveness": 0.0,
            "challenge_ok": False,
            "challenge_score": 0.0,
        }

        challenge_seen = False
        challenge_peak = 0.0
        liveness_scores = []

        a = np.array(request.storedVector, dtype=np.float32)

        for idx, frame_b64 in enumerate(request.framesBase64[:12]):  # cap to 12 frames
            header, encoded = frame_b64.split(",", 1) if "," in frame_b64 else ("", frame_b64)
            try:
                image_data = base64.b64decode(encoded)
            except Exception:
                continue

            nparr = np.frombuffer(image_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is None:
                continue

            is_live, lscore = check_liveness(img)
            liveness_scores.append(float(lscore))

            h, w = img.shape[:2]
            landmarks = _extract_face_landmarks(img)
            ok, cscore = _challenge_satisfied(request.challengeType, landmarks, w, h)
            challenge_seen = challenge_seen or ok
            if abs(cscore) > abs(challenge_peak):
                challenge_peak = cscore

            # Only compute embedding on potentially live frames (faster)
            if not is_live or lscore < 80:
                continue

            try:
                live_results = DeepFace.represent(img_path=img, model_name=MODEL_NAME, enforce_detection=True)
            except Exception:
                continue
            if not live_results:
                continue

            live_vector = np.array(live_results[0]["embedding"], dtype=np.float32)
            if a.shape[0] != live_vector.shape[0]:
                continue

            cos_sim = float(np.dot(a, live_vector) / (np.linalg.norm(a) * np.linalg.norm(live_vector)))
            if np.isnan(cos_sim):
                cos_sim = 0.0

            if cos_sim > best["similarity"]:
                best.update(
                    {
                        "similarity": cos_sim,
                        "frame_idx": idx,
                        "liveness": float(lscore),
                        "challenge_ok": ok,
                        "challenge_score": float(cscore),
                    }
                )

        avg_liveness = float(np.mean(liveness_scores)) if liveness_scores else 0.0

        if not challenge_seen:
            return {
                "similarity": 0.0,
                "isMatch": False,
                "isLive": False,
                "livenessScore": round(avg_liveness, 2),
                "message": f"Không đạt thử thách {request.challengeType}. Vui lòng thực hiện lại.",
            }

        similarity = best["similarity"]
        is_match = bool(similarity >= 0.40)

        return {
            "similarity": round(similarity, 4),
            "isMatch": is_match,
            "isLive": True,
            "livenessScore": round(avg_liveness, 2),
            "message": "Thành công" if is_match else f"Khuôn mặt không khớp ({round(similarity*100, 1)}%)",
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
