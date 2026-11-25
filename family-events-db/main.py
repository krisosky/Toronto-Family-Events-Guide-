from datetime import datetime, time, timedelta, timezone
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(
    title="Family Events Guide API",
    description="Backend API for Toronto Family Events Guide",
    version="1.0.0"
)

# Allow WordPress to call the API
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

def get_weekend_date_range():
    """Calculates Saturday 00:00:00 to Sunday 23:59:59 UTC."""
    now = datetime.now(timezone.utc)
    weekday = now.weekday()  # Monday = 0, ..., Saturday = 5, Sunday = 6

    if weekday == 5:    # Saturday
        sat_date = now.date()
    elif weekday == 6:  # Sunday
        sat_date = now.date() - timedelta(days=1)
    else:               # Monday - Friday
        days_until_saturday = 5 - weekday
        sat_date = now.date() + timedelta(days=days_until_saturday)

    sun_date = sat_date + timedelta(days=1)

    weekend_start = datetime.combine(sat_date, time.min, tzinfo=timezone.utc)
    weekend_end = datetime.combine(sun_date, time.max, tzinfo=timezone.utc)
    return weekend_start, weekend_end

@app.get("/")
def root():
    return {
        "service": "Family Events Guide API",
        "status": "healthy",
        "docs_url": "/docs"
    }

@app.get("/api/v1/events/free")
def get_free_events(city: str = Query(default="Toronto", description="City name to filter events")):
    """Returns upcoming, published, free events for a city."""
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

@app.get("/api/v1/events/this-weekend")
def get_this_weekend_events(city: str = Query(default="Toronto", description="City name")):
    """Returns published events occurring during the upcoming Saturday & Sunday."""
    weekend_start, weekend_end = get_weekend_date_range()
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        query = """
        SELECT 
            e.id,
            e.title,
            e.short_description,
            e.is_free,
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
          AND o.cancelled = FALSE
          AND o.starts_at <= %s
          AND o.ends_at >= %s
        GROUP BY e.id, v.name, v.street_address
        ORDER BY next_start_time ASC;
        """

        cursor.execute(query, (city, weekend_end, weekend_start))
        events = cursor.fetchall()
        cursor.close()

        for ev in events:
            if ev.get("next_start_time"):
                ev["next_start_time"] = ev["next_start_time"].isoformat()
            if ev.get("next_end_time"):
                ev["next_end_time"] = ev["next_end_time"].isoformat()

        return {
            "city": city,
            "weekend_start": weekend_start.isoformat(),
            "weekend_end": weekend_end.isoformat(),
            "total": len(events),
            "events": events
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        if conn:
            conn.close()
