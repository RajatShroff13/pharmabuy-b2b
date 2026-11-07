# Setup guide

Everything needed to run **PharmaBuy B2B** on Windows, plus the common failure modes.
The short version lives in the [README](../README.md#getting-started); this page goes into
the details.

---

## 1. Prerequisites

| Component | Version | Check |
| --- | --- | --- |
| Python | 3.10 or newer | `python --version` |
| SQL Server | 2019 or newer (Express is fine) | `sqlcmd -S localhost\SQLEXPRESS -E -Q "SELECT @@VERSION"` |
| ODBC Driver 17 for SQL Server | latest | `python -c "import pyodbc; print(pyodbc.drivers())"` |
| SQL Server Management Studio | optional | GUI alternative to `sqlcmd` |

If `pyodbc.drivers()` does not list `ODBC Driver 17 for SQL Server`, install it from
<https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server>.
ODBC Driver 18 also works — set `DB_DRIVER=ODBC Driver 18 for SQL Server` in `.env`.

---

## 2. Create the database

Run the scripts in order. All three are idempotent enough to re-run while developing: the
schema drops and recreates the tables, and `sample_data.sql` clears them before inserting.

```bash
sqlcmd -S localhost\SQLEXPRESS -E -i database/schema.sql
sqlcmd -S localhost\SQLEXPRESS -E -i database/sample_data.sql
sqlcmd -S localhost\SQLEXPRESS -E -i database/seed_admin_logins.sql
```

### Using SSMS instead

1. Connect to `localhost\SQLEXPRESS` with Windows authentication.
2. `File → Open → File…` and pick `database/schema.sql`, then press **Execute** (F5).
3. Repeat for `sample_data.sql` and `seed_admin_logins.sql`.

### If the database already exists

`schema.sql` starts with `create database Ph_Store;`, so skip that line (or run the script
against a fresh `Ph_Store`). To bring an older database up to date with the current
application, apply the migration scripts:

```bash
sqlcmd -S localhost\SQLEXPRESS -E -i database/migrations/001_customer_account_columns.sql
```

### Verify

```sql
USE Ph_Store;
SELECT COUNT(*) AS medicines FROM Medicine;      -- 290 with the demo data
SELECT COUNT(*) AS batches   FROM Batch;         -- 425
SELECT * FROM User_Login;                        -- admin, manager1, pharmacist1, cashier1, ...
```

---

## 3. Install the Python dependencies

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

`requirements.txt` installs Flask, Werkzeug, `pyodbc`, `python-dotenv` and `requests`.
Nothing is compiled locally, so a plain `pip install` is enough.

---

## 4. Configure `.env`

```bash
copy .env.example .env
```

Generate a session key:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Paste it into `SECRET_KEY`. Then set the connection values:

```dotenv
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=Ph_Store
DB_DRIVER=ODBC Driver 17 for SQL Server
DB_TRUSTED_CONNECTION=yes
```

Using SQL Server authentication instead of Windows authentication:

```dotenv
DB_TRUSTED_CONNECTION=no
DB_USERNAME=sa
DB_PASSWORD=YourStrong!Passw0rd
```

`.env` is git-ignored. Never commit it and never paste real credentials into an issue.

---

## 5. Run

```bash
python app.py
```

* URL: <http://127.0.0.1:5000>
* Debug reloader: set `FLASK_DEBUG=1` in `.env`
* Different port: `set PORT=5050` before `python app.py`

Or double-click **`start_server.bat`**, which creates `.env` from the example on first run,
installs dependencies and launches the app.

Sign in with `admin` / `admin123` (see the demo credentials table in the README).

---

## 6. Optional integrations

### n8n invoice webhook

After a successful checkout the app POSTs a JSON payload (order id, customer, items, total) to
`N8N_WEBHOOK_URL`. The call has a 5-second timeout and every exception is swallowed, so the
store works fine when n8n is not running. To use it, set the URL in `.env`:

```dotenv
N8N_WEBHOOK_URL=http://localhost:5678/webhook/pharmacy-invoice
```

### Production-ish hosting

The Flask development server is single-process and not hardened. On Windows:

```bash
pip install waitress
waitress-serve --listen=127.0.0.1:8000 app:app
```

On Linux/macOS use `gunicorn -w 4 app:app`. Put it behind a reverse proxy with HTTPS and keep
`FLASK_DEBUG=0`.

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Data source name not found` | ODBC driver missing or name mismatch | Install Driver 17, or set `DB_DRIVER` to the installed version |
| `Login failed for user` | `DB_TRUSTED_CONNECTION` set to `no` without credentials | Fill `DB_USERNAME` / `DB_PASSWORD`, or switch back to `yes` |
| `Cannot open database "Ph_Store"` | Schema not created | Run `database/schema.sql` |
| Login always says *Invalid username or password* | `User_Login` is empty | Run `database/seed_admin_logins.sql` |
| `Invalid column name 'email'` | Database created from the old schema | Run `database/migrations/001_customer_account_columns.sql` |
| Catalog is empty | Every batch in the database is expired | Re-run `database/sample_data.sql`, or add batches with future expiry dates |
| Sessions reset on every restart | No `SECRET_KEY`, so a random one is generated per boot | Set a fixed `SECRET_KEY` in `.env` |
| `pyodbc` install fails | No Python headers on Linux | `sudo apt install unixodbc-dev` then retry |
| Port 5000 already in use | Another process owns it | `set PORT=5050`, or stop the other process |

### Reset the demo data

```bash
sqlcmd -S localhost\SQLEXPRESS -E -i database/schema.sql
sqlcmd -S localhost\SQLEXPRESS -E -i database/sample_data.sql
sqlcmd -S localhost\SQLEXPRESS -E -i database/seed_admin_logins.sql
```

This drops every table, so any orders placed during testing are removed too.

---

## 8. Before publishing changes

- `git status` should never show `.env`, `server.log`, `__pycache__/` or a virtualenv.
- Search the diff for real hostnames, usernames or passwords.
- Re-run the app and click through login → catalog → cart → checkout → order history.
- If you changed SQL, run the affected page against the database rather than trusting the diff.
