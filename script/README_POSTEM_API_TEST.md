# Postem API test script

## Overview

Test script for the freebmd postem api integration. validates that myopicvicar can successfully create postems via the perl api endpoint.

## API keys

The API key for `freebmd1-test` (`vervet`) can be found at
`/usr/local/etc/apache24/envvars.d/freebmd-api.env`. 

```
source /usr/local/etc/apache24/envvars.d/freebmd-api.env
```

To test against the production servers look for the equaivalent file there.
 
The script expects the key to be exported as `FREEBMD_API_KEY`

## Usage

```bash
export FREEBMD_POSTEM_API_URL='https://www.freebmd.org.uk/api/create-postem.pl'
export FREEBMD_API_KEY='...' # if using production key
bundle exec rails runner script/test_postem_api.rb
```


### with debug output

```bash
DEBUG=1 bundle exec rails runner script/test_postem_api.rb
```

## what it tests

1. **configuration check**
   - verifies environment variables are set
   - shows api url and key status

2. **test record selection**
   - finds a bestguess record with hash
   - displays record details

3. **dry-run with valid postem**
   - calls api with `dry_run: true`
   - expects 412 response
   - verifies no data written

4. **dry-run with validation error**
   - tests postem without spaces
   - expects validation error
   - verifies error handling

5. **verify no data created**
   - checks postem count unchanged
   - checks confirmed flag unchanged

6. **optional real postem creation**
   - prompts user for confirmation
   - creates actual postem if approved
   - verifies postem in database
   - suggests log files to check

## expected output

```
================================================================================
  configuration check
================================================================================
✓ FREEBMD_API_KEY is set (length: 32 chars)
✓ api url: https://www.freebmd.org.uk/api/create-postem.pl

================================================================================
  finding test record
================================================================================
✓ found record: 123456
ℹ   surname: SMITH
ℹ   given name: JOHN
ℹ   district: HACKNEY
ℹ   year/quarter: 1900 Mar
ℹ   hash: pLUyEljbdaNYGzlPyvShnw
ℹ   database: bmd_1234567890

================================================================================
  test 1: dry-run with valid postem
================================================================================
✓ dry-run validation passed
ℹ response:
{
  "success": false,
  "dry_run": true,
  "message": "Dry-run: Postem would be created successfully",
  "validation": "passed",
  "code": 412
}

================================================================================
  test 2: dry-run with validation error
================================================================================
✓ rails-side validation caught error
ℹ error: information must contain at least one space

================================================================================
  test 3: verify no data created by dry-runs
================================================================================
ℹ postems for this record before tests: 0
✓ record does not have ENTRY_POSTEM flag (good for dry-run test)

================================================================================
  test 4: real postem creation (optional)
================================================================================
create a real postem for testing? this will write to the database. (y/N): n
ℹ skipping real postem creation

================================================================================
  test summary
================================================================================
✓ all dry-run tests completed
ℹ check apache error log for [DRY-RUN] entries:
  tail /var/log/apache2/error.log | grep DRY-RUN
```

## troubleshooting

### "FREEBMD_POSTEM_API_URL not set"

set the environment variable:
```bash
export FREEBMD_POSTEM_API_URL='https://www.freebmd.org.uk/api/create-postem.pl'
```

or add to `.env` file:
```
FREEBMD_POSTEM_API_URL=https://www.freebmd.org.uk/api/create-postem.pl
FREEBMD_API_KEY=your-secret-key
```

### "no bestguess records found in database"

the test database is empty. seed some data first:
```bash
bundle exec rake db:seed
```

or connect to a database with existing records.

### "authentication failed: invalid api key"

verify the api key matches between rails and perl:
```bash
# check rails side
echo $FREEBMD_API_KEY

# check perl side (on freebmd server)
grep FREEBMD_API_KEY /etc/apache2/envvars
```

### "connection refused" or timeout

verify the perl api endpoint is accessible:
```bash
curl -I https://www.freebmd.org.uk/api/create-postem.pl
```

if running locally, use localhost:
```bash
export FREEBMD_POSTEM_API_URL='http://localhost/api/create-postem.pl'
```

### colorize gem missing

if you see errors about `colorize`, install it:
```bash
bundle add colorize
```

or remove color formatting from script (replace `.colorize(:color)` with empty string).

## dependencies

- rails environment loaded
- `FreebmdPostemService` class available
- `BestGuess`, `BestGuessHash`, `Postem` models available
- `colorize` gem (optional, for colored output)

## files

- `script/test_postem_api.rb` - main test script
- `app/services/freebmd_postem_service.rb` - service being tested
- `app/controllers/postems_controller_new.rb` - controller using service

## see also

- `../FreeBMD/api/test-dry-run.sh` - bash script for testing perl endpoint directly
- `../FreeBMD/docs/claude/postem-api-dry-run.md` - dry-run feature documentation
- `../FreeBMD/docs/claude/postem-api-architecture.md` - full api architecture guide
