from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(
    title="Family Events Guide API",
    description="Backend API for Toronto Family Events Guide",
    version="1.0.0"
)

# Enable CORS so WordPress or frontend browsers can call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_CONFIG = {
    "dbname": "family_events",
    "user": "events_admin",
    "password": "secretpassword123",
    "host": "localhost",
    "port": 5433
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

@app.get("/")
def root():
    return {
        "service": "Family Events Guide API",
        "status": "healthy",
        "docs_url": "/docs"
    }

@app.get("/api/v1/events/free")
def get_free_events(city: str = Query(default="Toronto", description="City name to filter events")):
    """
    Returns upcoming, published, free events for a city.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        query = """
        SELECT 
            e.id,
            e.title,
            e.short_description,
            e.setting,
            e.minimum_age,
            e.maximum_age,
            e.image_url,
            v.name AS venue_name,
            v.street_address,
            MIN(o.starts_at) AS next_start_time,
            MAX(o.ends_at) AS next_end_time
        FROM events e
        JOIN cities c ON e.city_id = c.id
        JOIN event_occurrences o ON e.id = o.event_id
        LEFT JOIN venues v ON e.venue_id = v.id
        WHERE c.name ILIKE %s
          AND e.status = 'published'
          AND e.is_free = TRUE
          AND o.cancelled = FALSE
          AND o.ends_at >= NOW()
        GROUP BY e.id, v.name, v.street_address
        ORDER BY next_start_time ASC;
        """

        cursor.execute(query, (city,))
        events = cursor.fetchall()
        cursor.close()

        # Format timestamps as ISO strings for JSON serialization
        for ev in events:
            if ev.get("next_start_time"):
                ev["next_start_time"] = ev["next_start_time"].isoformat()
            if ev.get("next_end_time"):
                ev["next_end_time"] = ev["next_end_time"].isoformat()

        return {
            "city": city,
            "total": len(events),
            "events": events
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
