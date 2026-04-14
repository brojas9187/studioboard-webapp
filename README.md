# StudioBoard

StudioBoard is a small multi-tenant SaaS built with Rails 8, Tailwind, and Hotwire.

## MVP included

- User registration, sign in, and sign out
- Organization creation with automatic `owner` membership
- Membership roles: `owner`, `admin`, `member`
- Project CRUD with role-based permissions
- Task creation, completion toggle, and deletion inside projects
- Free vs Pro plans with enforced limits
- Stripe Checkout upgrade flow in test mode
- Webhook-driven upgrade to Pro
- Server-rendered UI with Tailwind
- Turbo-powered task updates without full page reloads

## Roles

- `owner`: billing, organization settings, project deletion
- `admin`: create and edit projects, create and manage tasks
- `member`: view projects, create tasks, manage their own tasks

## Plans

- `Free`: up to 2 projects, up to 3 members
- `Pro`: unlimited projects, unlimited members

## Local setup

1. Install dependencies.
2. Make sure PostgreSQL is running locally.
3. Prepare the database:

```bash
bin/rails db:prepare
```

4. Start the app:

```bash
bin/dev
```

## Stripe test configuration

You can place these values in a local `.env` file for `bin/dev`, or export them manually before using the Billing page:

```bash
export STRIPE_SECRET_KEY=sk_test_...
export STRIPE_PRICE_ID=price_...
export STRIPE_WEBHOOK_SECRET=whsec_...
export STRIPE_PAYMENT_METHOD_TYPES=card,link
```

Webhook endpoint:

```text
POST /stripe/webhook
```

For local development with the Stripe CLI:

```bash
stripe listen --forward-to http://localhost:3000/stripe/webhook
```

The Billing page now supports:

- Stripe Checkout for the initial upgrade
- Stripe Billing Portal to manage saved payment methods, billing details, invoices, and subscription data

## Railway deploy

Railway will automatically use this app's `Dockerfile` during deployment.

Recommended app variables:

```bash
RAILS_MASTER_KEY=...
DATABASE_URL=${{Postgres.DATABASE_URL}}
SOLID_QUEUE_IN_PUMA=true
```

`RAILS_MASTER_KEY` must be the exact contents of `config/master.key`.
It is not the same value as `secret_key_base`, and it should be pasted without quotes or extra whitespace.

Optional app variables:

```bash
APP_URL=https://your-app.up.railway.app
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
STRIPE_SECRET_KEY=...
STRIPE_PRICE_ID=...
STRIPE_WEBHOOK_SECRET=...
STRIPE_PAYMENT_METHOD_TYPES=card,link
```

Notes:

- Production can run from a single PostgreSQL database on Railway. `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, and `CABLE_DATABASE_URL` are optional overrides if you ever want dedicated databases later.
- If `APP_URL` is not set, the app will fall back to Railway's `RAILWAY_PUBLIC_DOMAIN` when present.
- The container now starts Rails on `0.0.0.0:$PORT`, which matches Railway's healthcheck expectations.

Suggested Railway flow:

1. Create a web service from this repository.
2. Add a PostgreSQL service.
3. Set `DATABASE_URL` in the app service to `${{Postgres.DATABASE_URL}}`.
4. Set `RAILS_MASTER_KEY` and `SOLID_QUEUE_IN_PUMA=true`.
5. Generate a public domain in Railway Networking.
6. Redeploy.

Healthcheck endpoint:

```text
GET /up
```

## Google sign-in

Set these environment variables, or place them in `.env`, to enable Google OAuth:

```bash
export APP_URL=http://localhost:3000
export GOOGLE_CLIENT_ID=...
export GOOGLE_CLIENT_SECRET=...
```

Use this callback URL in the Google Cloud Console:

```text
http://localhost:3000/auth/google_oauth2/callback
```

That callback must match exactly, including protocol, host, and port. For example, `localhost` and `127.0.0.1` are different values for Google.

For Railway, that callback will usually look like:

```text
https://your-app.up.railway.app/auth/google_oauth2/callback
```

Google sign-in links users by email when a matching local account already exists.

## Test suite

```bash
bin/rails test
```

