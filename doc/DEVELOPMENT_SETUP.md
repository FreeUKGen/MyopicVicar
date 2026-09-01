# Development Setup — FreePRO (freeprobate)

This page covers the **`freeprobate_development`** branch, which runs the same MyopicVicar codebase in `freepro` mode
(probate records).


## Two tiers

| Tier | What you get | What you need |
|------|---------------|----------------|
| **A — Code & PRs** | Boots the app, no probate data | Ruby, MongoDB, gems, config files |
| **B — Full local FreePRO** | Tier A + real probate records to search/browse | Tier A + a probate JSON dump |

---

## Prerequisites

| Component | Version / notes |
|-----------|------------------|
| **Ruby** | **2.6.7** (see `.ruby-version`). Use [rbenv](https://github.com/rbenv/rbenv): `rbenv install 2.6.7`. |
| **Bundler** | Compatible with Ruby 2.6.7 (`Gemfile.lock` was built with Bundler 2.4.22) |
| **MongoDB** | 4.4+, running locally for `rails s`. |
| **Node.js** | Needed to precompile assets (`assets.compile` is off in development, same as FreeREG). |
| **MySQL** | Not needed. `config/database.yml` only exists so Rails can boot (`rails/all` pulls in ActiveRecord); nothing on this branch actually queries MySQL since Refinery is disabled. Placeholder values from `database.example.yml` are fine. |
| **osgb gem** | Not needed here — the `osgb` git dependency is commented out in this branch's `Gemfile`, so you don't need to clone it separately. |

---

## Quick start (Tier A)

```bash
git clone https://github.com/FreeUKGen/MyopicVicar.git
cd MyopicVicar
git checkout freeprobate_development

# Ruby 2.6.7 (rbenv example)
rbenv install 2.6.7
rbenv local 2.6.7

bundle install

# Start MongoDB first (Ubuntu example)
sudo systemctl start mongod
```

### Config files (never commit these — all gitignored)

Copy each example to its real name, then edit as noted:

| Copy from | To | Edit needed for FreePRO |
|-----------|-----|--------------------------|
| `config/freeukgen_application_example.yml` | `config/freeukgen_application.yml` | Set `template_set: 'freepro'` in every environment block |
| `config/mongoid_example.yml` | `config/mongoid.yml` | Set the `default` client's `database:` to `freepro_development` (and the `test` client to `freepro_test` if you'll run specs) |
| `config/mongo_config.example.yml` | `config/mongo_config.yml` | Fill in `mongodb_bin_location`, `datafiles`, `website: 'localhost:3000'`, `our_secret_key`, `secret_key_base` — the rest can stay blank/default for Tier A |
| `config/database.example.yml` | `config/database.yml` | No edits needed — placeholder values, MySQL is never actually used |
| `config/secrets.example.yml` | `config/secrets.yml` | Fill in any `secret_key_base` value |
| `config/application.example.yml` | `config/application.yml` | Only needed if you want to test outgoing mail via Gmail |
| `config/errbit.config.yml` | `config/errbit.yml` | Only needed for error reporting; leave as-is to skip |

```bash
# Run app
bundle exec rails s
# → http://localhost:3000
```

`config/freeukgen_application.yml`:

```yaml
development:
  template_set: 'freepro'
  gtm_key: ''
  advert_key:
    data_ad_client: ""
    data_ad_slot_header: ""
```

Restart `rails s` after changing this file.

---

## Tier B — Load probate data

Sample data lives outside the repo as a plain JSON array export of the `probates` collection
(extended JSON, e.g. `"_id": {"$oid": "..."}`). One such dump used in development:
`freeprobate_development.probates.json` (2,265 records).

Import it directly with `mongoimport` — no rake task is needed:

```bash
mongoimport --db freepro_development --collection probates --jsonArray \
  --file /path/to/freeprobate_development.probates.json
```

Verify:

```bash
mongo
use freepro_development
db.probates.countDocuments({})
db.probates.findOne()
```

The `Probate` model (`app/models/probate.rb`) is a dynamic-attributes Mongoid document that embeds
`death`, `event`, and `executors` — the imported JSON's `Death`/`Event`/`Event.Person` structure
maps onto those via `Mongoid::Attributes::Dynamic`, so no schema migration step is required.

### Search indexes

Unlike FreeREG/FreeCEN, FreePRO search does **not** currently use a named MongoDB index hint —
`SearchRecord.best_index` returns `nil` for `template_set == 'freepro'` (see
`app/models/search_record.rb`), so you don't need to run anything from `doc/design/indexes/` to get
name/date field search working here. This is expected to change as FreePRO search matures — check
that file if search behavior around indexing changes.

Free-text search is a different story: `SearchQuery#freepro_search_records`
(`app/models/search_query.rb`) runs a `$text`/`$search` query whenever a text search term is
present, and MongoDB **requires an actual text index** to execute `$text` — without it the query
raises at runtime instead of just running unindexed. Load the companion index dump alongside the
data import:

`freeprobate_development.probates_indexes.json` is a `db.probates.getIndexes()` export (index
specs, not a `mongorestore` file), so `mongoimport` can't load it — use a short `mongosh` script
instead:

```bash
mongosh freepro_development --eval '
  const indexes = JSON.parse(require("fs").readFileSync("/path/to/freeprobate_development.probates_indexes.json", "utf8"));
  indexes.forEach(idx => {
    const { key, name, ...options } = idx;
    if (name !== "_id_") db.probates.createIndex(key, { name, ...options });
  });
'
```

Verify:

```bash
mongosh freepro_development --eval 'db.probates.getIndexes()'
```

You need this to exercise free-text search locally; name/date field search works without it.

---

## Which app am I running?

`config/freeukgen_application.yml` → `template_set: 'freepro'` (vs `freereg`/`freecen`/`freebmd`).
`config/application.rb` uses this to select `app/assets_freepro` for styles/images and set
`config.freexxx_display_name = 'FreePRO'`.

---

## Troubleshooting

| Problem | Check |
|---------|-------|
| Mongo connection errors | `mongod` running; `config/mongoid.yml` host/port |
| App crashes on boot with no clear Mongo error | `config/database.yml` missing — copy `config/database.example.yml` |
| Wrong skin / assets (FreeREG images/styles showing) | `template_set` in `config/freeukgen_application.yml` isn't `'freepro'`; restart `rails s` after editing |
| Blank probate search results | Tier B import not done, or wrong `database:` name in `config/mongoid.yml` |
| `filter_map` / Ruby version errors | Use Ruby **2.6.7**, not 2.7+ (this branch predates the FreeREG guide's 2.7.8 branch) |
| Pages load with no CSS/JS | `config.assets.compile = false` in development — run `bundle exec rake assets:precompile` (needs Node.js) |

---

## Git workflow

FreePRO work happens on `freeprobate_development`, not `master`, until it's ready to merge upstream:

```bash
git checkout freeprobate_development
git pull
git checkout -b fp_issue_number_you_are_working_on
# … edit …
git push -u origin fp_issue_number_you_are_working_on
```

Open a PR targeting `freeprobate_development`.
