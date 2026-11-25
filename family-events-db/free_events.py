import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    "dbname": "family_events",
    "user": "events_admin",
    "password": "secretpassword123",
    "host": "localhost",
    "port": 5433
}

def get_free_events():
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
        cursor = conn.cursor()

        query = """
        SELECT 
            e.id,
            e.title,
            e.short_description,
            e.setting,
            e.minimum_age,
            e.maximum_age,
            v.name AS venue_name,
            v.street_address,
            MIN(o.starts_at) AS next_start_time
        FROM events e
        JOIN cities c ON e.city_id = c.id
        JOIN event_occurrences o ON e.id = o.event_id
        LEFT JOIN venues v ON e.venue_id = v.id
        WHERE c.name = 'Toronto'
          AND e.status = 'published'
          AND e.is_free = TRUE
          AND o.cancelled = FALSE
          AND o.ends_at >= NOW()
        GROUP BY e.id, v.name, v.street_address
        ORDER BY next_start_time ASC;
        """

        cursor.execute(query)
        events = cursor.fetchall()
        cursor.close()
        return events

    except Exception as error:
        print(f"Database error: {error}")
        return []
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    free_events = get_free_events()
    print("=" * 60)
    print(f"🎉 TOTAL FREE PUBLISHED EVENTS IN TORONTO: {len(free_events)}")
    print("=" * 60)
    for event in free_events:
        print(f"\nTitle:       {event['title']}")
        print(f"Venue:       {event['venue_name']} ({event['street_address']})")
        print(f"Next Start:  {event['next_start_time']}")
        print(f"Setting:     {event['setting']}")
        print(f"Age Range:   {event['minimum_age']} - {event['maximum_age']} years")
        print("-" * 60)
