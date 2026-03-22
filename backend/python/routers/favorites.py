from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from models.database import get_pool
from typing import Literal

router = APIRouter()

ItemType = Literal["video", "music", "social_video", "social_music"]


class FavoriteCreate(BaseModel):
    item_type:     ItemType
    video_id:      str | None = None   # internal video UUID
    external_id:   str | None = None   # social platform ID
    platform:      str | None = None
    title:         str | None = None
    thumbnail_url: str | None = None
    media_url:     str | None = None
    author_name:   str | None = None
    duration:      float | None = None
    metadata:      dict = {}


@router.get("/favorites/{profile_id}")
async def list_favorites(
    profile_id: str,
    item_type: str | None = Query(None),
    platform:  str | None = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    pool = await get_pool()
    filters = ["profile_id = $1"]
    params: list = [profile_id]

    if item_type:
        params.append(item_type)
        filters.append(f"item_type = ${len(params)}")
    if platform:
        params.append(platform)
        filters.append(f"platform = ${len(params)}")

    where = " AND ".join(filters)
    params += [limit, offset]

    rows = await pool.fetch(
        f"""
        SELECT id, item_type, video_id, external_id, platform, title,
               thumbnail_url, media_url, author_name, duration, metadata, created_at
        FROM favorites
        WHERE {where}
        ORDER BY created_at DESC
        LIMIT ${len(params)-1} OFFSET ${len(params)}
        """,
        *params,
    )
    return {"favorites": [dict(r) for r in rows], "total": len(rows)}


@router.post("/favorites/{profile_id}")
async def add_favorite(profile_id: str, fav: FavoriteCreate):
    pool = await get_pool()
    try:
        row = await pool.fetchrow(
            """
            INSERT INTO favorites
                (profile_id, item_type, video_id, external_id, platform,
                 title, thumbnail_url, media_url, author_name, duration, metadata)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
            ON CONFLICT DO NOTHING
            RETURNING id
            """,
            profile_id,
            fav.item_type,
            fav.video_id,
            fav.external_id,
            fav.platform,
            fav.title,
            fav.thumbnail_url,
            fav.media_url,
            fav.author_name,
            fav.duration,
            fav.metadata,
        )
        return {"id": str(row["id"]) if row else None, "ok": True}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/favorites/{profile_id}/{favorite_id}")
async def remove_favorite(profile_id: str, favorite_id: str):
    pool = await get_pool()
    result = await pool.execute(
        "DELETE FROM favorites WHERE id = $1 AND profile_id = $2",
        favorite_id, profile_id,
    )
    if result == "DELETE 0":
        raise HTTPException(status_code=404, detail="Favorite not found")
    return {"ok": True}


@router.get("/favorites/{profile_id}/check")
async def is_favorited(profile_id: str, external_id: str = Query(...)):
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT id FROM favorites WHERE profile_id = $1 AND external_id = $2 LIMIT 1",
        profile_id, external_id,
    )
    return {"is_favorite": row is not None, "id": str(row["id"]) if row else None}
