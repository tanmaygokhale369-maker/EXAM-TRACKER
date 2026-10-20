# Exam Tracker API

## Configuration

Set `JWT_SECRET` to a unique, unpredictable signing key and `ADMIN_PASSWORD`
to a unique admin password before starting the API. The admin password is only
used when the admin account is first created; it is not printed or reset for an
existing account.

For PowerShell:

```powershell
$env:JWT_SECRET = "<generate a unique, unpredictable value>"
$env:ADMIN_PASSWORD = "<choose a unique password>"
python app.py
```

Run the command from this directory. Keep these values out of source control.
