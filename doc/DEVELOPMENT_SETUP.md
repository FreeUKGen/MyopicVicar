# MyopicVicar development setup

This guide replaces the archived PDF *Installing FreeREG on your development facility*.
It reflects the current stack: **Rails 6.1**, **Mongoid/MongoDB**, and **optional** legacy MySQL/Refinery.

## Two tiers

| Tier | Who | Time | What you need |
|------|-----|------|----------------|
| **A — Code & PRs** | Most bug fixes, controllers, services | ~1–2 hours | Ruby, MongoDB, gems, config files, test3 account |
| **B — Full local FreeREG** | Search, CSV upload, coordinators | ~half day | Tier A + collection imports + sample datafiles from mentor |

Most developers can work in **Tier A** and verify on **https://test.freereg.org.uk/** without loading entire production datasets.

---

## Prerequisites

### Operating system

- **Linux** or **WSL2** on Windows is strongly recommended.
- Native Windows is possible but more fragile (paths, MongoDB, gems).

### Software

| Component | Version / notes |
|-----------|-----------------|
| **Ruby** | **2.7.8** (see `.ruby-version`). Use [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/). |
| **Bundler** | Latest compatible with Ruby 2.7 |
| **MongoDB** | 4.4+ (local install or Docker). Server must be running for `rails s`. Download link: https://www.mongodb.com/try/download/community|
| **Git** | Clone [MyopicVicar](https://github.com/FreeUKGen/MyopicVicar) and [osgb](https://github.com/FreeUKGen/osgb) (osgb is a Gemfile dependency). |
| **MySQL** | Not needed — `bin/setup` handles the one placeholder file the app requires. See [MySQL / Refinery](#mysql--refinery-you-can-ignore-this-section) below. |
| **Node.js** | Needed for `bin/setup` to precompile assets (`config.assets.compile` is off in development here, unlike a stock Rails app — see Troubleshooting). Only likely to be missing on some Linux setups. |

### Accounts

1. Register on **https://test.freereg.org.uk/** (use the **test3** syndicate).
2. Ask your mentor to assign a **technical** role to your userid.


---

## Quick start (Tier A)

```bash
git clone https://github.com/FreeUKGen/MyopicVicar.git
cd MyopicVicar

# Ruby 2.7.8 (rbenv example)
rbenv install 2.7.8
rbenv local 2.7.8

# Start MongoDB first (Ubuntu example) - bin/setup only seeds the
# testuser4 test login below if MongoDB is already running
sudo systemctl start mongod

# Automated config + directories
chmod +x bin/setup bin/dev-*
bin/setup

# Edit local settings
#   config/mongo_config.yml      — bin/setup already fills in datafiles/website/secrets;
#                                   only edit if you want non-default values
#   config/freeukgen_application.yml — template_set: 'freereg'

# Run app
bundle exec rails s
# → http://localhost:3000  (log in as testuser4 / testuser4)
```

`bin/setup` seeds a local `testuser4` / `testuser4` login automatically (if MongoDB is already
running when you run it). This works regardless of the random `our_secret_key` generated on your
machine, because the password digest is computed fresh, locally, at seed time - unlike any
`UseridDetail`/`User` records imported from a mentor's data dump, whose passwords were digested
with a different `our_secret_key` and won't verify here. Re-run it any time with:

```bash
bundle exec rake "dev:seed_test_login[testuser4,testuser4]"
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
| `config/database.example.yml` | `config/database.yml` | Required for boot only (see MySQL / Refinery below) — placeholder values are fine |

`bin/setup` copies these automatically if missing and fills development secrets in `mongo_config.yml`.

### MySQL / Refinery (you can ignore this section)

**You do not need to install MySQL.** `bin/setup` automatically creates a placeholder
`config/database.yml` for you, and that's all the app needs — nothing in normal FreeREG
development actually connects to a MySQL server. (If you're curious why the file has to exist at
all when it's unused: `config/application.rb` loads `rails/all`, which pulls in
`ActiveRecord::Railtie`, and Rails won't boot without *a* `config/database.yml` present, even a
fake one.)

This section only matters if a mentor asks you to work on legacy Refinery CMS features (rare —
`refinerycms` gems are commented out in the Gemfile):

- Do **not** run `rake db:migrate` unless told to.
- To set up a real MySQL server: create MySQL DB `freereg2_development`, put real credentials in
  `config/database.yml`, then follow legacy steps in old docs.

---

## Tier B — Reference data and search

Obtain from your mentor / FreeUKGen **Files for Development** (Google Drive):

- `collections.zip` — JSON dumps for core Mongo collections
- `datafiles.zip` — sample transcriber CSV datafiles

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

Put datafiles under `tmp/datafiles/testuser4/` from mentor's `datafiles.zip`

```bash
mkdir -p tmp/datafiles/testuser4
cp dev_setup/datafiles/*.csv tmp/datafiles/testuser4/
```

Then process them into the database in one step:

```bash
bin/dev-load-csv-data
```

This runs (in order): `bin/dev-create-search-indexes` (see below), `freeuk:add_user` (creates a
Devise `User` for each `UseridDetail`), `load_emendations`, `build:recommence_freereg_new_update[...]`
to create `freereg1_csv_entries` and `search_records`, and `foo:refresh_places_cache`. Add
`--with-content` to also rebuild `freereg_contents` via `freereg:calculate_freereg_content` —
skipped by default since it can take 30-60+ minutes. These steps are slow and hardware-dependent;
ask a mentor for a minimal county range of real data if you need more than the fixtures.

### Search indexes (required for search to work)

`search_records` queries are run with a named MongoDB index hint (e.g. `county_fn_ln_rt_sd_ssd`,
picked in `app/models/search_record.rb`). Those indexes are **not** created by Mongoid's normal
`create_indexes` — they're defined as raw `createIndexes` commands in
`doc/design/indexes/search_records.reg` (and `.cen` for FreeCEN), meant to be run directly against
Mongo. Without them, search fails with:

```
planner returned error :: caused by :: hint provided does not correspond to an existing index (2)
```

Run once per database:

```bash
bin/dev-create-search-indexes
```

`bin/dev-load-csv-data` already calls this for you, but you can re-run it standalone at any time —
it's idempotent (`createIndexes` is a no-op if the index already exists with the same spec).

---

## Mail in development

- By default, no real email is sent: `config/initializers/setup_mail.rb` only enables real Gmail SMTP if `gmail_username`/`gmail_password` are set; otherwise mail delivery is a safe no-op (see `raise_delivery_errors` there).
- All development mail is trapped by `lib/development_mail_interceptor.rb` and redirected — set `dev_mail_recipient` in `config/application.yml` (from `application.example.yml`) to your own address if you want to actually see trapped mail; it defaults to a non-deliverable placeholder.
- To test real Gmail SMTP delivery, fill in `gmail_username`/`gmail_password` in `config/application.yml` too.
- Restart Rails after mail config changes.

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
| App crashes on boot (`rails s`/`rails runner`/`rails console`) with no clear Mongo error | `config/database.yml` missing — run `bin/setup` or copy `config/database.example.yml` |
| Blank site / no places | Tier B imports not done |
| Cannot log in locally | userid on test3 + `userid_details` imported; not the old Refinery `demo` user |
| `filter_map` / Ruby errors | Use Ruby **2.7.8**, not 2.6 |
| Pages load with no CSS/JS at all | `bin/setup` runs `assets:precompile` for you, but this app has `config.assets.compile = false` in development (no on-the-fly fallback like a stock Rails app), so if it failed - often for missing Node.js - install Node.js and rerun `bundle exec rake assets:precompile` |
| Search fails: "hint provided does not correspond to an existing index" | Run `bin/dev-create-search-indexes` |

---

## Git workflow

```bash
git checkout master
git pull
git checkout -b fr_issue_number_you_are_working_on # here fr stands for FreeREG, fc for FreeCEN, fb for FreeBMD2. eg fr_1234
# … edit …
git push -u origin fr_issue_number_you_are_working_on
```

Open a PR on GitHub.

---

## Summary for mentors

| Required for all devs | Optional |
|-----------------------|----------|
| Ruby 2.7.8, bundle, MongoDB | A real MySQL server + Refinery |
| Config files from examples (`bin/setup` handles this, including the placeholder `database.yml` the app needs just to boot) | Full `users.zip` rebuild |
| test registration + technical role | Production-sized data |
| `bin/setup` | |

**Mongo + test is enough for most developers.** Full local search needs Tier B data from the team share.
