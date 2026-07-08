from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_healthz():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert "GitOps" in resp.json()["message"]


def test_version_defaults_to_dev(monkeypatch):
    monkeypatch.delenv("APP_VERSION", raising=False)
    resp = client.get("/version")
    assert resp.status_code == 200
    assert resp.json() == {"version": "dev"}
