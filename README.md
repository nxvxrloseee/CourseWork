# RepairDesk (CW)

Курсовая. Система для сервисного центра по ремонту техники. Три клиента + один бэк.

## Из чего состоит

- **RD/** — бэкенд. Spring Boot 3.5, JDK 17, PostgreSQL 16, JPA/Hibernate (`ddl-auto=update`), Redis, RabbitMQ, MinIO, STOMP-WS для чата. Поднимается через `docker-compose.yml`.
- **rd-master/** — веб-морда для мастера и админа. React + Vite + TypeScript. Дашборд с графиком выручки, тикеты, чат, прайс, услуги.
- **rd-customer/** — мобилка для заказчика. Flutter (Android/iOS). Регистрация, создание тикета, чат с мастером, FCM-пуши.
- **tests/** — pytest-набор по REST API (`test_api.py`, `test_dashboard.py`) и bash-скрипт целостности БД (`test_integrity.sh`).

## Как поднять

```bash
cd RD
docker compose up -d
```

Поднимется стек: `rd-backend`, `rd-postgres`, `rd-redis`, `rd-rabbitmq`, `rd-minio`, `rd-frontend`. Бэк слушает 8080, фронт — 5173.

Мобилка отдельно:
```bash
cd rd-customer
flutter pub get
flutter run
```

## Что внутри бэка

- `controller/` — REST-эндпоинты
- `service/` — бизнес-логика
- `repository/` — Spring Data JPA
- `entity/` — модели (тикеты, юзеры, чат, прайс, услуги, нотификации и т.д.)
- `security/` — JWT + refresh в httpOnly-куке, bcrypt cost=12
- `exception/GlobalExceptionHandler.java` — централизованная обработка ошибок (400/404/500 + кастомные)
- `config/` — WS, Redis, RabbitMQ, MinIO

## Бэкапы БД

`RD/backup.sh` — `pg_dump --schema-only` + `--data-only`. Складывается в `RD/backups/`. Восстановление: остановить `rd-backend`, `pg_terminate_backend`, DROP/CREATE, накатить дамп, поднять бэк.
