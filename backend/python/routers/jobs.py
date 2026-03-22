from fastapi import APIRouter, HTTPException
from models.database import get_job

router = APIRouter()


@router.get("/jobs/{job_id}")
async def poll_job(job_id: str):
    job = await get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job
