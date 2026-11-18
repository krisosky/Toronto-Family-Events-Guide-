-- 1. Check created tables
SELECT table_name FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;

-- 2. Public upcoming Toronto events (active occurrences only)
SELECT e.id, e.title, c.name AS city, o.starts_at, o.ends_at, e.is_free
FROM events e
JOIN cities c ON e.city_id = c.id
JOIN regions r ON c.region_id = r.id
JOIN countries n ON r.country_id = n.id
JOIN event_occurrences o ON o.event_id = e.id
WHERE e.status = 'published'
  AND o.cancelled = false
  AND o.ends_at >= now()
  AND c.name = 'Toronto' AND n.iso_code = 'CA'
ORDER BY o.starts_at;

-- 3. Free public upcoming Toronto events
SELECT e.title, o.starts_at FROM events e
JOIN cities c ON c.id=e.city_id
JOIN event_occurrences o ON o.event_id=e.id
WHERE e.status='published' AND e.is_free=true AND o.cancelled=false
  AND o.ends_at >= now() AND c.name='Toronto'
ORDER BY o.starts_at;

-- 4. Published events occurring during the demo weekend, Toronto local time
-- Explicit window avoids dependence on the day the test is executed.
SELECT e.title, o.starts_at FROM events e
JOIN event_occurrences o ON o.event_id=e.id
WHERE e.status='published' AND o.cancelled=false
  AND o.starts_at < '2026-11-23 00:00:00-05'::timestamptz
  AND o.ends_at > '2026-11-21 00:00:00-05'::timestamptz
ORDER BY o.starts_at;

-- 5. Pending events for admin review (should NOT appear publicly)
SELECT id, title, status FROM events WHERE status='pending_review';

-- 6. All categories for every demo event
SELECT e.title, string_agg(c.name, ', ' ORDER BY c.name) AS categories
FROM events e JOIN event_categories ec ON ec.event_id=e.id
JOIN categories c ON c.id=ec.category_id
GROUP BY e.id,e.title ORDER BY e.id;
