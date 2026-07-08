"""Sample API — minimale FastAPI-App für die GitOps-/CI-CD-Demo.

Health-Endpoint für Kubernetes-Probes, Root-Endpoint als Lebenszeichen und
ein /version-Endpoint, der den (per CI gesetzten) Image-Tag zurückgibt.
"""
import os

from fastapi import FastAPI

app = FastAPI(title="Sample API", version=os.getenv("APP_VERSION", "dev"))


@app.get("/healthz")
def healthz() -> dict[str, str]:
    """Liveness/Readiness-Probe-Ziel."""
    return {"status": "ok"}


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Azure DevOps Demo — running via GitOps"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": os.getenv("APP_VERSION", "dev")}
