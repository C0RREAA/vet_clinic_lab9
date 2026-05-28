# VetClinic

A small Ruby on Rails application for managing a veterinary clinic — owners,
their pets, vets, appointments and treatments — built across a series of labs
for UANDES.

## Stack

- Ruby 3.2.2
- Rails 8.1.3
- PostgreSQL
- Bootstrap 5.3 (via CDN)
- Active Storage (pet photos, with image variants via libvips)
- Action Text / Trix (treatment clinical notes)
- Devise (authentication, with role enum)
- Pundit (role-based authorization with per-resource policies)

## System dependencies

### libvips (required)

Pet photo thumbnails are generated through Active Storage variants, which
the `image_processing` gem performs against **libvips**. Without libvips
installed system-wide the image variant calls fail at runtime.

On macOS with Homebrew:

```bash
brew install vips
```

Verify:

```bash
which vips
```

### PostgreSQL

```bash
brew services start postgresql@16
```

If you hit encoding issues creating the dev DB on macOS, use:

```bash
psql -U Pancho -d postgres -c "CREATE DATABASE vet_clinic_development TEMPLATE template0 ENCODING 'UTF8';"
```

## Setup

```bash
bundle install
bin/rails db:setup     # creates DB, loads schema, runs seeds
bin/rails server
```

Then open http://localhost:3000.

## Troubleshooting

### PostgreSQL encoding issue (SQL_ASCII clusters)

If `bin/rails db:create` fails with

```
new encoding (UTF8) is incompatible with the encoding of the template database (SQL_ASCII)
```

create the databases manually using `template0`:

```bash
psql -d postgres <<'SQL'
CREATE DATABASE vet_clinic_development ENCODING 'UTF8' TEMPLATE template0;
CREATE DATABASE vet_clinic_test        ENCODING 'UTF8' TEMPLATE template0;
SQL
bin/rails db:migrate db:seed
```

## Running tests

```bash
bin/rails test
```

## Authentication & authorization

Every page except the public landing (`pages#home`) is behind a Devise
login — hitting `/pets`, `/vets`, `/appointments`, `/owners/:id` while
signed out redirects to `/users/sign_in`. **Self-registration is disabled**:
the `/users/sign_up` route does not exist. New accounts are created via
seeds or the admin console.

Once a user is signed in, every controller action runs through a Pundit
policy. The `index` action calls `policy_scope(Model)`, so a non-admin
sees only the rows they're entitled to; every other action calls
`authorize @record`. Action buttons (`Edit`, `Delete`, `New …`) are wrapped
in `policy(record).action?` checks so the UI only offers what the user is
allowed to do.

### Role matrix (short version)

| Resource    | Admin     | Vet                                          | Owner                                                    |
| ----------- | --------- | -------------------------------------------- | -------------------------------------------------------- |
| Owner       | full CRUD | index + show all                             | show / edit only their own record; no `/owners` listing  |
| Pet         | full CRUD | index + show all                             | full CRUD scoped to their own pets (owner_id is forced)  |
| Vet         | full CRUD | index + show all; edit only their own record | index + show only                                        |
| Appointment | full CRUD | scoped to appointments where `vet.user = me` | scoped to appointments where `pet.owner.user = me`       |
| Treatment   | full CRUD | only on appointments assigned to them        | read-only via the parent appointment                     |

Unauthorized access raises `Pundit::NotAuthorizedError`, which
`ApplicationController` rescues into a flash-alert + redirect back.

### Seeded credentials

All passwords: `password123`. Users are upserted with `find_or_create_by!`
so `db:seed` is safe to re-run.

**Admin**

| Email                  | Linked record |
| ---------------------- | ------------- |
| `admin@vetclinic.com`  | none          |

**Vets**

| Email                  | Linked Vet record  |
| ---------------------- | ------------------ |
| `vet@vetclinic.com`    | Dr. Jane Smith     |
| `vet2@vetclinic.com`   | Dr. Carlos Mendoza |

**Owners**

| Email                  | Linked Owner record    |
| ---------------------- | ---------------------- |
| `owner@vetclinic.com`  | John Doe (2 pets)      |
| `owner2@vetclinic.com` | Maria García (2 pets)  |

There's also an unlinked Owner record (Lucía Fernández, 2 pets) that only
an admin can manage — useful for verifying the `policy_scope` behaviour.

### Role is server-controlled

`role` is **not** in any user-facing permitted-parameters list. Even a
crafted POST that includes `user[role]=admin` would be silently dropped.
Promotions happen in the seed file or `rails console`.

## Trix sanitization check

Action Text uses Trix and runs incoming HTML through Rails' sanitizer before
rendering. As a quick smoke test, paste the following into a treatment's
clinical-notes field through the UI:

```html
<script>alert(1)</script>
```

When the appointment page is reloaded the `<script>` tag is stripped — the
text is shown as plain content and **no alert fires**. The same goes for
inline event handlers (`onerror=`, `onclick=` …) and `javascript:` URLs.

## Notable lab milestones

- **Lab 3** — initial models, validations, schema.
- **Lab 4** — Bootstrap layout, navbar, index/show views.
- **Lab 5** — enums, scopes, callbacks, eager loading, flash messages.
- **Lab 6** — full CRUD across all resources, nested treatments, error
  partial with `is-invalid` Bootstrap styling.
- **Lab 7** — Active Storage for pet photos (with size/MIME validation and
  thumbnail variants) and Action Text for rich clinical notes on treatments.
- **Lab 8** — Devise authentication: protected resource pages, sign-in /
  sign-up / account-edit views styled to match the rest of the app, a `role`
  enum that the user-facing forms can't touch, and three seeded accounts
  (admin, vet, owner) for quick login testing.
- **Lab 9** — Pundit authorization: five resource policies, scoped
  `index` queries, `verify_authorized` / `verify_policy_scoped` enforcement
  in `ApplicationController`, policy-gated action buttons, role-aware
  navbar, a real public landing page in `PagesController`, and a richer
  seed (5 users covering all three roles, with two owner-linked and two
  vet-linked records).
