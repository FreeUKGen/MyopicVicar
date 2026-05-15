# MyopicVicar development setup

This guide replaces the archived PDF *Installing FreeREG on your development facility*.
It reflects the current stack: **Rails 6.1**, **Mongoid/MongoDB**, and **optional** legacy MySQL/Refinery.

## Two tiers

| Tier | Who | Time | What you need |
|------|-----|------|----------------|
| **A — Code & PRs** | Most bug fixes, controllers, services | ~1–2 hours | Ruby, MongoDB, gems, config files, test3 account |
| **B — Full local FreeREG** | Search, CSV upload, coordinators | ~half day | Tier A + collection imports + sample datafiles from mentor |

Most developers can work in **Tier A** and verify on **https://test3.freereg.org.uk/** without loading entire production datasets.

---

## Prerequisites

### Operating system

- **Linux** or **WSL2** on Windows is strongly recommended.
- Native Windows is possible but more fragile (paths, MongoDB, gems).

### Software

| Component | Version / notes |
|-----------|-----------------|
| **Ruby** | **2.7.8** (see `.ruby-version`). Use [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/). |
| **Bundler** | Latest compatible with Ruby 2.7 |
| **MongoDB** | 4.4+ (local install or Docker). Server must be running for `rails s`. |
| **Git** | Clone [MyopicVicar](https://github.com/FreeUKGen/MyopicVicar) and [osgb](https://github.com/FreeUKGen/osgb) (osgb is a Gemfile dependency). |
| **MySQL** | **Optional** — only for legacy Refinery CMS tasks. Refinery gems are **commented out** in the Gemfile. |
| **Node.js** | Only if the asset pipeline fails on first `rails s` (rare on Linux). |

### Accounts

1. Register on **https://test3.freereg.org.uk/** (use the **technical** syndicate).
2. Ask your mentor to assign a **technical** role to your userid.
3. Join the FreeUKGen Slack / complete the [tech volunteer form](https://www.freeukgenealogy.org.uk/about/volunteer/tech-volunteering-opportunities/) (see [CONTRIBUTING.md](../CONTRIBUTING.md)).

---

## Quick start (Tier A)

```bash
git clone https://github.com/FreeUKGen/MyopicVicar.git
cd MyopicVicar

# Ruby 2.7.8 (rbenv example)
rbenv install 2.7.8
rbenv local 2.7.8

# Automated config + directories
chmod +x bin/setup bin/dev-import-collections
bin/setup

# Edit local settings
#   config/mongo_config.yml      — datafiles path, website, secrets
#   config/freeukgen_application.yml — template_set: 'freereg'

# Start MongoDB (Ubuntu example)
sudo systemctl start mongod

# Run app
bundle exec rails s
# → http://localhost:3000
```

### Config files (never commit these)

| Copy from | To | Purpose |
|-----------|-----|---------|
| `config/mongoid_example.yml` | `config/mongoid.yml` | MongoDB database name and host |
| `config/mongo_config.example.yml` | `config/mongo_config.yml` | datafiles path, website URL, secret keys |
| `config/freeukgen_application_example.yml` | `config/freeukgen_application.yml` | Which app skin: `freereg`, `freecen`, `freebmd` |
| `config/application.example.yml` | `config/application.yml` | Optional Gmail env for mail tests |
| `config/secrets.example.yml` | `config/secrets.yml` | Legacy secrets file |
| `config/errbit.example.yml` | `config/errbit.yml` | Error reporting stub (development) |

`bin/setup` copies these automatically if missing and fills development secrets in `mongo_config.yml`.

### MySQL / Refinery

**Not required** for typical FreeREG development today:

- `Gemfile` has `refinerycms` gems commented out.
- Do **not** run `rake db:migrate` unless a mentor explicitly needs Refinery work.
- If needed: copy `config/database.example.yml` → `config/database.yml`, create MySQL DB `freereg2_development`, then follow legacy steps in old docs.

---

## Tier B — Reference data and search

Obtain from your mentor / FreeUKGen **Files for Development** (Google Drive):

- `collections.zip` — JSON dumps for core Mongo collections
- `users.zip` — sample transcriber CSV datafiles (optional)
- Your `.uDetails` file from test3 registration

### Import reference collections

```bash
# Unzip collections/*.json into tmp/
bin/dev-import-collections tmp/
```

Imports (with `--drop` per collection): places, churches, counties, countries, denominations, registers, syndicates, userid_details, emendation_rules, emendation_types.

Verify:

```bash
mongo
use myopic_vicar_development   # or your name from config/mongoid.yml
db.places.countDocuments()
```

### Sample transcriptions (optional)

With datafiles under `tmp/datafiles/<userid>/` (from mentor):

```bash
rake load_emendations --trace
rake build:recommence_freereg_new_update[create_search_records,range,force_rebuild,a-9] --trace
rake foo:refresh_places_cache
rake freereg:calculate_freereg_content --trace
```

These steps are slow and hardware-dependent; ask a mentor for a minimal county range if possible.

### Link userid to the app

```bash
rake load_refinery_users --trace   # legacy name; links UseridDetail users where applicable
```

### System administrator (optional)

In `lib/create_userid_docs.rb`, after the existing role lines, your mentor may add:

```ruby
header[:person_role] = "system_administrator" if header[:userid] == "YOUR_USERID"
```

---

## Mail in development

- Edit `lib/development_mail_interceptor.rb` so trapped mail goes to **your** address (not a personal Gmail hard-coded in the repo).
- For Gmail SMTP, use `config/application.yml` (from `application.example.yml`) and see `config/initializers/setup_mail.rb`.
- Restart Rails after mail config changes.

---

## Running tests

```bash
bundle exec rspec
```

Tests use the `test` MongoDB database from `config/mongoid.yml`.

---

## Which app am I running?

`config/freeukgen_application.yml`:

```yaml
development:
  template_set: 'freereg'   # or freecen, freebmd
```

Restart `rails s` after changing.

---

## Troubleshooting

| Problem | Check |
|---------|--------|
| Mongo connection errors | `mongod` running; `config/mongoid.yml` host/port |
| `mongo_config.yml` missing | Run `bin/setup` |
| `errbit.yml` missing | Run `bin/setup` or copy `config/errbit.example.yml` |
| Blank site / no places | Tier B imports not done |
| Cannot log in locally | userid on test3 + `userid_details` imported; not the old Refinery `demo` user |
| `filter_map` / Ruby errors | Use Ruby **2.7.8**, not 2.6 |
| Assets timeout on `rails s` | Install Node.js |

---

## Git workflow

```bash
git checkout master
git pull
git checkout -b your_name_short_description
# … edit …
git push -u origin your_name_short_description
```

Open a PR on GitHub. See [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## Related documentation

- [README.md](../README.md)
- [Google Doc installation notes](https://docs.google.com/document/d/11n5F9WB9WA9BgZwj1QDJf2OdZOPO1-jkdY1cXOU-AHE/edit) (may be newer than archived PDFs)
- In-app help pages under `app/views/pages/freereg/` (some legacy build docs)

---

## Summary for mentors

| Required for all devs | Optional |
|-----------------------|----------|
| Ruby 2.7.8, bundle, MongoDB | MySQL + Refinery |
| Config files from examples | Full `users.zip` rebuild |
| test3 registration + technical role | Production-sized data |
| `bin/setup` | |

**Mongo + test3 is enough for most developers.** Full local search needs Tier B data from the team share.
