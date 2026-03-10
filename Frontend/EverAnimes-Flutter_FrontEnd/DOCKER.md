# Docker instructions

Build the image locally:

```bash
docker build -t everanimes-web:latest .
```

Run with Docker (maps to http://localhost:5173):

```bash
docker run --rm -p 5173:80 everanimes-web:latest
```

Or use docker-compose (recommended):

```bash
docker-compose up --build -d
```

The app will be available at http://localhost:5173/
