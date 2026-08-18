import base64
from unittest.mock import patch

import numpy as np
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_embed_rejects_unsupported_mime():
    response = client.post(
        "/internal/ai/embed", files={"file": ("payload.txt", b"not-image", "text/plain")}
    )
    assert response.status_code == 415


@patch("main.cv2.imdecode", return_value=None)
def test_embed_rejects_invalid_image(_):
    response = client.post(
        "/internal/ai/embed", files={"file": ("broken.jpg", b"not-image", "image/jpeg")}
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid image data."


@patch("main.MAX_IMAGE_BYTES", 4)
def test_embed_rejects_oversized_upload():
    response = client.post(
        "/internal/ai/embed", files={"file": ("large.png", b"12345", "image/png")}
    )
    assert response.status_code == 413


@patch("main.check_liveness", return_value=(True, 100.0))
@patch("main.DeepFace.represent", return_value=[{"embedding": [0.1] * 128}])
@patch("main.cv2.imdecode", return_value=np.zeros((8, 8, 3), dtype=np.uint8))
def test_compare_normalizes_success(_, mock_represent, __):
    encoded = base64.b64encode(b"image").decode()
    response = client.post(
        "/internal/ai/compare",
        json={"storedVector": [0.1] * 128, "liveImageBase64": encoded},
    )
    assert response.status_code == 200
    assert response.json()["isMatch"] is True
    mock_represent.assert_called_once()


def test_compare_rejects_invalid_base64():
    response = client.post(
        "/internal/ai/compare",
        json={"storedVector": [0.1] * 128, "liveImageBase64": "not%%%base64"},
    )
    assert response.status_code == 400


@patch("main.check_liveness", return_value=(True, 100.0))
@patch("main.DeepFace.represent", side_effect=RuntimeError("sensitive native detail"))
@patch("main.cv2.imdecode", return_value=np.zeros((8, 8, 3), dtype=np.uint8))
def test_compare_does_not_leak_internal_exception(_, __, ___):
    encoded = base64.b64encode(b"image").decode()
    response = client.post(
        "/internal/ai/compare",
        json={"storedVector": [0.1] * 128, "liveImageBase64": encoded},
    )
    assert response.status_code == 400
    assert "sensitive native detail" not in response.text
