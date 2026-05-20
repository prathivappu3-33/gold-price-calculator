# AGENTS.md

## Cursor Cloud specific instructions

This is a static single-page web application (Gold Price Calculator) with no build system, no package manager, and no dependencies to install.

### Running the application

Serve the project root with any static HTTP server:

```bash
python3 -m http.server 8080 --directory /workspace
```

Then open `http://localhost:8080/` in a browser. The app uses fallback hardcoded gold rates when the external GoldAPI is unreachable, so it works fully offline.

### Project structure

- `index.html` — the entire application (HTML + inline CSS + inline JS)
- `index_old.html` — previous version, kept for reference

### Lint / Test / Build

There are no linting tools, test frameworks, or build steps configured. The project is a single self-contained HTML file.

### Notes

- The app fetches live gold prices from `https://api.goldapi.io/api/XAU/INR` using the token `goldapi-demo`. If the API call fails (network issues, rate limiting, invalid token), the app gracefully falls back to hardcoded rates.
- No environment variables or secrets are required to run the application.
