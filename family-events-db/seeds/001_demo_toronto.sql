-- FICTIONAL DEMO EVENTS ONLY. NOT ACTUAL PUBLISHED TORONTO EVENTS.
-- Demo dates target Nov 2026; edit dates if demonstrating in another period.
BEGIN;
INSERT INTO countries (iso_code,name) VALUES ('CA','Canada') ON CONFLICT (iso_code) DO NOTHING;
INSERT INTO regions (country_id,name,code)
SELECT id,'Ontario','ON' FROM countries WHERE iso_code='CA'
ON CONFLICT (country_id,name) DO NOTHING;
INSERT INTO cities (region_id,name,timezone)
SELECT id,'Toronto','America/Toronto' FROM regions WHERE name='Ontario' AND country_id=(SELECT id FROM countries WHERE iso_code='CA')
ON CONFLICT (region_id,name) DO NOTHING;
INSERT INTO organizers (name,website_url,contact_email)
VALUES ('Sample Community Organizer', 'https://example.org', 'demo@example.org');
INSERT INTO venues (city_id,name,street_address)
VALUES ((SELECT c.id FROM cities c JOIN regions r ON c.region_id=r.id JOIN countries n ON r.country_id=n.id WHERE c.name='Toronto' AND n.iso_code='CA'),
        'Demo Community Hall', '100 Example Street');
INSERT INTO categories (name,slug) VALUES
 ('Free events','free-events'),('Festivals','festivals'),('Indoor fun','indoor-fun'),
 ('Outdoor fun','outdoor-fun'),('Arts & culture','arts-culture'),
 ('Sports & Recreation','sports-recreation'),('Educational','educational'),
 ('Music & Entertainment','music-entertainment'),('Community Events','community-events'),
 ('Seasonal Events','seasonal-events'),('Camps & Programs','camps-programs')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO events (organizer_id,venue_id,city_id,title,short_description,description,is_free,status,official_source_url,setting)
SELECT o.id,v.id,v.city_id,'DEMO: Family Art Day','Sample free event','Demonstration data, not a real event',TRUE,'published','https://example.org/demo-art','indoor'
FROM organizers o CROSS JOIN venues v WHERE o.name='Sample Community Organizer' AND v.name='Demo Community Hall' ORDER BY o.id DESC, v.id DESC LIMIT 1;
INSERT INTO events (organizer_id,venue_id,city_id,title,short_description,description,is_free,price_min,price_max,status,official_source_url,setting)
SELECT o.id,v.id,v.city_id,'DEMO: Weekend Festival','Sample paid event','Demonstration data, not a real event',FALSE,10,20,'published','https://example.org/demo-festival','outdoor'
FROM organizers o CROSS JOIN venues v WHERE o.name='Sample Community Organizer' AND v.name='Demo Community Hall' ORDER BY o.id DESC, v.id DESC LIMIT 1;
INSERT INTO events (organizer_id,venue_id,city_id,title,description,is_free,status,official_source_url)
SELECT o.id,v.id,v.city_id,'DEMO: Pending Workshop','Should not appear in public results',TRUE,'pending_review','https://example.org/demo-pending'
FROM organizers o CROSS JOIN venues v WHERE o.name='Sample Community Organizer' AND v.name='Demo Community Hall' ORDER BY o.id DESC, v.id DESC LIMIT 1;

INSERT INTO event_occurrences (event_id,starts_at,ends_at)
SELECT id,'2026-11-21 10:00:00-05'::timestamptz,'2026-11-21 12:00:00-05'::timestamptz FROM events WHERE title='DEMO: Family Art Day';
INSERT INTO event_occurrences (event_id,starts_at,ends_at)
SELECT id,'2026-11-22 13:00:00-05'::timestamptz,'2026-11-22 17:00:00-05'::timestamptz FROM events WHERE title='DEMO: Weekend Festival';
INSERT INTO event_occurrences (event_id,starts_at,ends_at)
SELECT id,'2026-11-21 15:00:00-05'::timestamptz,'2026-11-21 16:00:00-05'::timestamptz FROM events WHERE title='DEMO: Pending Workshop';
INSERT INTO event_categories (event_id,category_id)
SELECT e.id,c.id FROM events e CROSS JOIN categories c WHERE
 (e.title='DEMO: Family Art Day' AND c.slug IN ('free-events','arts-culture')) OR
 (e.title='DEMO: Weekend Festival' AND c.slug IN ('festivals','outdoor-fun')) OR
 (e.title='DEMO: Pending Workshop' AND c.slug='educational');
COMMIT;
