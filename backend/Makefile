.PHONY: help dev prod build down logs shell db-shell test db-migrate db-rollback db-reset clean

help:
	@echo "Docker Commands:"
	@echo "  make dev         - Run development environment (hot reload)"
	@echo "  make prod        - Run production environment"
	@echo "  make build       - Build Docker images"
	@echo "  make down        - Stop all containers"
	@echo "  make logs        - View container logs"
	@echo "  make shell       - Shell into app container"
	@echo "  make db-shell    - PostgreSQL shell"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate  - Run migrations"
	@echo "  make db-rollback - Rollback migration"
	@echo "  make db-reset    - Reset database"
	@echo ""
	@echo "Testing & Utilities:"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Clean cache files"

dev:
	@echo "Starting development environment..."
	docker-compose up --build

prod:
	@echo "Starting production environment..."
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d

build:
	@echo "Building Docker images..."
	docker-compose build

down:
	@echo "Stopping containers..."
	docker-compose down

logs:
	@echo "Viewing logs (Ctrl+C to exit)..."
	docker-compose logs -f

shell:
	@echo "Opening shell in app container..."
	docker-compose exec fastapi-app /bin/bash

db-shell:
	@echo "Opening PostgreSQL shell..."
	docker-compose exec postgres-db psql -U ${DB_USER:-dislexia} -d ${DB_NAME:-dislexia_db}

test:
	@echo "Running tests..."
	docker-compose exec fastapi-app pytest tests/ -v

db-migrate:
	@echo "Running migrations..."
	docker-compose exec fastapi-app alembic upgrade head

db-rollback:
	@echo "Rolling back migration..."
	docker-compose exec fastapi-app alembic downgrade -1

db-reset:
	@echo "Resetting database..."
	docker-compose exec fastapi-app alembic downgrade base
	docker-compose exec fastapi-app alembic upgrade head

clean:
	@echo "Cleaning cache files..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "Done!"
