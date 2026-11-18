
# Family Events Guide - Database

This folder db the PostgreSQL database for the Family Events Guide application. The database stores event information, organizers, locations, categories, event schedules, and administrative review records.

The database runs in a Docker container and is designed to support events in Toronto initially, with the ability to expand to other cities and countries.

The backend API will communicate with PostgreSQL to retrieve, create, and update event records. WordPress maintains its own separate database.

## 1. Project Structure

```text
family-events-db/
├── migrations/
│   └── 001_initial_schema.sql
├── seeds/
│   └── 001_demo_toronto.sql
├── tests/
│   └── demo_queries.sql
├── .env
├── .gitignore
├── docker-compose.yml
└── README.md
```

- `migrations/` - SQL scripts for creating the database tables, relationships, constraints, and indexes.
- `seeds/` - Sample Toronto event data used for testing.
- `tests/` - SQL queries for verifying database functionality.
- `docker-compose.yml` - PostgreSQL container configuration.
- `.env` - Local database credentials and port configuration.

## 2. Database Setup

Requirements:
- Docker Desktop
- VS Code with Git Bash terminal
- pgAdmin (optional)

Open the `family-events-db` folder in VS Code.

Ensure the `.env` file contains the database configuration:

```dotenv
POSTGRES_USER=events_admin
POSTGRES_PASSWORD=your_database_password
POSTGRES_DB=family_events
POSTGRES_PORT=5433
```

The password should match the credentials used when the PostgreSQL database was initialized.

Start PostgreSQL:

```bash
docker compose up -d
```

Check that the container is running:

```bash
docker compose ps
```

The database is accessible from the host computer at `localhost:5433`.

## 3. Creating the Tables

Run the initial SQL migration using Git Bash:

```bash
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U events_admin -d family_events < migrations/001_initial_schema.sql
```

This creates the 12 database tables along with their primary keys, foreign keys, constraints, and indexes.

Run this migration once when initializing a new database.

### Database Tables

| Table | Purpose |
|---|---|
| countries | Stores countries |
| regions | Stores provinces and states |
| cities | Stores cities and timezones |
| venues | Stores event venues and addresses |
| organizers | Stores event organizer information |
| events | Stores event details and publication statuses |
| event_occurrences | Stores scheduled event dates and times |
| categories | Stores event categories |
| event_categories | Associates events with multiple categories |
| event_reviews | Stores administrative review records |
| newsletter_subscribers | Stores newsletter subscription information |
| contact_submissions | Stores website contact form submissions |

## 4. Loading Test Data

Sample Toronto events are provided for testing.

Run:

```bash
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U events_admin -d family_events < seeds/001_demo_toronto.sql
```

This inserts fictional demonstration events with different categories, prices, dates, and publication statuses.

The sample data is intended for development and testing only.

## 5. Testing the Database

Run the provided SQL tests:

```bash
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U events_admin -d family_events < tests/demo_queries.sql
```

The queries demonstrate:

- Retrieving published Toronto events.
- Filtering free and paid events.
- Retrieving events by date.
- Identifying events awaiting administrative review.
- Retrieving event categories.
- Verifying that the database tables exist.

These tests confirm basic database functionality independently of the backend API.

## 6. Connecting the Backend API

The backend team can connect to PostgreSQL using the following settings:

| Setting | Value |
|---|---|
| Database | family_events |
| Username | events_admin |
| Host (local machine) | localhost |
| Port (local machine) | 5433 |
| Internal Docker port | 5432 |

If the backend runs in the same Docker Compose network, it can connect using:

```text
postgres:5432
```

If the backend runs directly on the developer's computer, use:

```text
localhost:5433
```

The backend developers can implement ORM models or SQL queries using the existing database schema.

SQL migration files are the source of truth for the database structure. Any changes to the schema should be coordinated with the database developer.

The PostgreSQL database does not directly communicate with WordPress. The backend API will be responsible for providing event data to the website.

## 7. Testing with the Application

Once the backend API is implemented, the database can be tested with the rest of the application using the following workflow:

1. Start PostgreSQL using Docker Compose.
2. Ensure the database schema has been created.
3. Load sample event data if necessary.
4. Start the backend API and connect it to PostgreSQL.
5. Request events through the API and verify the returned records.
6. Test creating, updating, and retrieving events through the API.
7. Verify that only published events appear in public event listings.
8. Test the website's event search and filtering functionality.

Database records can also be inspected directly using pgAdmin or SQL queries.

## 8. Using pgAdmin

To inspect the database visually, register a server in pgAdmin using:

```text
Host: localhost
Port: 5433
Database: family_events
Username: events_admin
Password: your configured password
```

Navigate to:

```text
Databases > family_events > Schemas > public > Tables
```

The database tables and their contents can be inspected using pgAdmin's Query Tool.

## 9. Stopping the Database

Stop the PostgreSQL container:

```bash
docker compose down
```

The database data is preserved in the Docker named volume.

To start it again:

```bash
docker compose up -d
```

Do not use `docker compose down -v` unless you intentionally want to delete the database volume and its stored data.

## 10. Current Implementation

The database currently provides:

- A relational schema for event management.
- Geographic relationships supporting multiple countries.
- Event categories and scheduled occurrences.
- Publication and verification status fields.
- Administrative review records.
- Basic constraints and indexes.
- Sample Toronto events and SQL test queries.

The backend API, authentication, automated publication workflows, WordPress integration, and external service integrations are separate development responsibilities.

This folder provides the database infrastructure and schema required for those components.
