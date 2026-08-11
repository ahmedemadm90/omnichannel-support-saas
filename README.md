# OmniChannel Support SaaS

OmniDesk is a real multi-tenant customer-support product for teams that need one inbox for WhatsApp, Telegram, email, and web conversations. The repository includes a Laravel API, Sanctum authentication, workspace isolation, a Flutter agent interface, Laravel Reverb broadcast events, and an importable n8n channel router.

## Product surface

| Capability | Implementation |
|---|---|
| Multi-tenancy | Workspaces, membership roles, and workspace-scoped contacts/conversations |
| Unified inbox | Open/pending/resolved filters, channel badges, priority, assignment, and message history |
| Agent actions | Reply to customers, resolve conversations, update priority, and inspect contact details |
| Channel ingestion | Signed inbound webhook accepts normalized WhatsApp, Telegram, email, or web messages |
| Real-time | `inbox.message.created` broadcasts on private `workspace.{id}` channels via Reverb |
| Mobile | Flutter Material 3 agent inbox with responsive split-pane layout on wide screens |
| Automation | n8n normalizes source payloads and delivers them to the Laravel inbox webhook |

## Run the backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

To enable real-time events in local development, configure the Reverb values from `.env.example`, then run:

```bash
php artisan reverb:start --host=0.0.0.0 --port=8080
```

Demo agent credentials:

| User | Email | Password |
|---|---|---|
| Workspace owner | `owner@omnichannel.test` | `password` |
| Support agent | `agent@omnichannel.test` | `password` |

The seeded workspace is `Acme Support Desk` with three contacts and conversations distributed across WhatsApp, Telegram, and email.

## Run the Flutter agent app

```bash
cd frontend
flutter pub get
flutter test
flutter analyze
flutter run
```

The Android emulator API host is configured as `10.0.2.2`. Update `frontend/lib/services/omnichannel_api.dart` for a physical device or remote backend.

The app logs in with the seeded owner account, loads the active workspace, displays the unified inbox, opens conversation history, sends agent replies, and resolves conversations.

## n8n channel router

Import `workflows/channel_router.json` into n8n and configure these n8n environment values:

```dotenv
LARAVEL_OMNI_WEBHOOK_URL=http://host.docker.internal:8000/api/v1/workspaces/1/webhooks/inbound
OMNI_WEBHOOK_SECRET=replace-with-the-same-value-used-by-Laravel
```

The workflow accepts a source payload such as:

```json
{
  "source": "telegram",
  "contact": {"name": "Nour Ali", "email": "nour@example.com"},
  "text": "I need help with my order"
}
```

It normalizes the source, signs the delivery, and sends it to Laravel, which creates or reuses the customer conversation and broadcasts the new message to agents.

## API surface

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/auth/register` | Create an owner and workspace |
| `POST` | `/api/v1/auth/login` | Issue a Sanctum token |
| `GET` | `/api/v1/workspaces` | List the current user's workspaces |
| `GET` | `/api/v1/workspaces/{id}/conversations` | Filter inbox conversations |
| `GET` | `/api/v1/workspaces/{id}/conversations/{id}` | Load a conversation and messages |
| `POST` | `/api/v1/workspaces/{id}/conversations/{id}/messages` | Send an agent reply |
| `PATCH` | `/api/v1/workspaces/{id}/conversations/{id}` | Update status or priority |
| `POST` | `/api/v1/workspaces/{id}/webhooks/inbound` | Receive signed channel events |

## Validation

```bash
cd backend
php artisan test --compact

cd ../frontend
flutter test
flutter analyze
```

## SaaS roadmap

The data model is ready for subscription metering through `plan` and `monthly_message_limit`. The next commercial layer can add Stripe billing, additional agent seats, provider-specific adapters, SLA reports, canned replies, and workspace-level analytics without weakening tenant isolation.

## Author

Ahmed Emad — Backend, Mobile, and Automation Developer.
