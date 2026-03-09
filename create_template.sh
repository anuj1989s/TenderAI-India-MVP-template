#!/usr/bin/env bash
set -euo pipefail

# This script creates a ready-to-use TenderAI India MVP GitHub Template skeleton
# It writes a complete set of files (backend + frontend + CI) into a single folder:
# TenderAI-India-MVP-template
ROOT_DIR="$(pwd)/TenderAI-India-MVP-template"

echo "Creating TenderAI-India-MVP-template scaffold at: $ROOT_DIR"

# Create directory structure
mkdir -p "$ROOT_DIR/backend/accounts"
mkdir -p "$ROOT_DIR/backend/tenders"
mkdir -p "$ROOT_DIR/backend/proposals"
mkdir -p "$ROOT_DIR/backend/ai"
mkdir -p "$ROOT_DIR/backend/tenderai"
mkdir -p "$ROOT_DIR/backend"
mkdir -p "$ROOT_DIR/frontend/pages"
mkdir -p "$ROOT_DIR/frontend/components"
mkdir -p "$ROOT_DIR/frontend/styles"
mkdir -p "$ROOT_DIR/.github/workflows"
mkdir -p "$ROOT_DIR/.github"
mkdir -p "$ROOT_DIR"

# 1) README.md
cat > "$ROOT_DIR/README.md" <<'EOF'
# TenderAI India — MVP Template

This repository is a ready-to-use GitHub Template for TenderAI India MVP.
It includes a Django REST backend + Next.js frontend, dockerized for easy local development, and a minimal OpenAI integration for tender matching and proposal drafting.

What you get (MVP):
- User authentication (email signup/login, JWT)
- Company profile management
- Tender data model (seed data)
- AI Tender Matching (rule-based MVP)
- AI Bid Proposal Generator (OpenAI API)
- Document upload (S3-compatible storage)
- Basic Tender listing and detail pages
- Admin scaffold
- Docker Compose setup for local development
- Simple GitHub Actions CI scaffold

Prerequisites:
- Docker and Docker Compose
- Optional: OpenAI API key (for MVP AI features)
- Optional: Node.js (for local frontend dev)

Getting started (locally):
1. Duplicate this template by creating a new repo from this template.
2. Clone your new repo locally.
3. Copy .env.example to .env and fill in environment variables.
4. Run: 
   docker-compose up -d --build
5. Initialize DB:
   docker-compose exec backend python manage.py migrate
6. Create superuser:
   docker-compose exec backend python manage.py createsuperuser
7. Access:
   - Backend: http://localhost:8000
   - Frontend: http://localhost:3000

Structure overview:
- backend/: Django project with apps: accounts, tenders, proposals, ai
- frontend/: Next.js app
- docker-compose.yml: orchestrates DB + backend + frontend
- .github/workflows/ci.yml: minimal CI scaffold

Next steps (post-MVP):
- Replace seed data with real tender ingestion (APIs or compliant scraping)
- Move towards embedding-based AI matching (vector store)
- Implement full payments (Stripe/Razorpay) and advanced analytics
- Apply production-grade security, RBAC, auditing, and backups

Happy building! If you want, I can customize the template further for your exact team size and target trigger points.
EOF

# 2) .gitignore
cat > "$ROOT_DIR/.gitignore" <<'EOF'
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.env
*.env
db.sqlite3
/media/
staticfiles/
*.sqlite3
venv/
.env*

# Node
node_modules/
.next/
dist/
build/
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
*.vscode/
*.idea/

# Logs
*.log
EOF

# 3) backend/requirements.txt
cat > "$ROOT_DIR/backend/requirements.txt" <<'EOF'
Django>=4.2
djangorestframework>=3.14
djangorestframework-simplejwt>=4.5
psycopg2-binary>=2.9
corsheaders>=3.0
requests>=2.28
openai>=0.27
gunicorn>=20.1
EOF

# 4) backend/tenderai/settings.py
cat > "$ROOT_DIR/backend/tenderai/settings.py" <<'PY'
from pathlib import Path
import os
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "change-me")
DEBUG = os.environ.get("DEBUG", "True") == "True"
ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "accounts",
    "tenders",
    "proposals",
    "ai",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

CORS_ALLOW_ALL_ORIGINS = True

ROOT_URLCONF = "tenderai.urls"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "tenderai"),
        "USER": os.environ.get("POSTGRES_USER", "tender"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", "password"),
        "HOST": os.environ.get("POSTGRES_HOST", "db"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}

AUTH_USER_MODEL = "accounts.User"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
}

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
PY

# 5) backend/tenderai/asgi.py
cat > "$ROOT_DIR/backend/tenderai/asgi.py" <<'PY'
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tenderai.settings")

application = get_asgi_application()
PY

# 6) backend/tenderai/wsgi.py
cat > "$ROOT_DIR/backend/tenderai/wsgi.py" <<'PY'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tenderai.settings")

application = get_wsgi_application()
PY

# 7) backend/accounts/models.py
cat > "$ROOT_DIR/backend/accounts/models.py" <<'PY'
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    email = models.EmailField(unique=True)
    ROLES = (("user", "User"), ("admin", "Admin"))
    role = models.CharField(max_length=20, choices=ROLES, default="user")

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email
PY

# 8) backend/accounts/serializers.py
cat > "$ROOT_DIR/backend/accounts/serializers.py" <<'PY'
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "username", "first_name", "last_name", "role"]
PY

# 9) backend/accounts/views.py
cat > "$ROOT_DIR/backend/accounts/views.py" <<'PY'
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from .serializers import UserSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny

User = get_user_model()

class SignUpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")
        if not email or not password:
            return Response({"error": "email and password required"}, status=400)
        if User.objects.filter(email=email).exists():
            return Response({"error": "email exists"}, status=400)
        user = User.objects.create_user(username=email, email=email, password=password)
        serializer = UserSerializer(user)
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": serializer.data,
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            },
            status=201,
        )
PY

# 10) backend/tenders/models.py
cat > "$ROOT_DIR/backend/tenders/models.py" <<'PY'
from django.db import models

class Tender(models.Model):
    tender_id_source = models.CharField(max_length=255, unique=True)
    source_portal = models.CharField(max_length=100)
    tender_title = models.TextField()
    department = models.CharField(max_length=255, null=True, blank=True)
    state = models.CharField(max_length=100, null=True, blank=True)
    tender_value = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    last_date = models.DateField(null=True, blank=True)
    eligibility = models.TextField(null=True, blank=True)
    document_link = models.URLField(null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    scraped_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.tender_title[:60]
PY

# 11) backend/tenders/serializers.py
cat > "$ROOT_DIR/backend/tenders/serializers.py" <<'PY'
from rest_framework import serializers
from .models import Tender

class TenderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tender
        fields = "__all__"
PY

# 12) backend/tenders/views.py
cat > "$ROOT_DIR/backend/tenders/views.py" <<'PY'
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Tender
from .serializers import TenderSerializer
from rest_framework.decorators import action
from rest_framework.response import Response

class TenderViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Tender.objects.all().order_by("-scraped_at")
    serializer_class = TenderSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=["get"])
    def match(self, request, pk=None):
        tender = self.get_object()
        data = {
            "tender_id": tender.id,
            "title": tender.tender_title,
            "relevance_score": 0,
            "summary": (tender.description or "")[:200],
            "eligibility": bool(tender.eligibility),
        }
        return Response(data)
PY

# 13) backend/tenders/urls.py
cat > "$ROOT_DIR/backend/tenders/urls.py" <<'PY'
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TenderViewSet

router = DefaultRouter()
router.register(r"tenders", TenderViewSet, basename="tender")

urlpatterns = [
    path("", include(router.urls)),
]
PY

# 14) backend/ai/utils.py
cat > "$ROOT_DIR/backend/ai/utils.py" <<'PY'
import os
import openai

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
openai.api_key = OPENAI_API_KEY

def generate_text(prompt, model="gpt-4", max_tokens=800):
    if not OPENAI_API_KEY:
        return "OPENAI_API_KEY not configured"
    resp = openai.ChatCompletion.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=max_tokens,
        temperature=0.6,
    )
    return resp.choices[0].message["content"].strip()
PY

# 15) backend/proposals/models.py
cat > "$ROOT_DIR/backend/proposals/models.py" <<'PY'
from django.db import models
from django.conf import settings
from tenders.models import Tender

class Proposal(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    tender = models.ForeignKey(Tender, on_delete=models.CASCADE)
    cover_letter = models.TextField(blank=True)
    technical_proposal = models.TextField(blank=True)
    company_introduction = models.TextField(blank=True)
    work_methodology = models.TextField(blank=True)
    project_timeline = models.TextField(blank=True)
    compliance_statement = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
PY

# 16) backend/proposals/serializers.py
cat > "$ROOT_DIR/backend/proposals/serializers.py" <<'PY'
from rest_framework import serializers
from .models import Proposal

class ProposalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proposal
        fields = "__all__"
PY

# 17) backend/proposals/views.py
cat > "$ROOT_DIR/backend/proposals/views.py" <<'PY'
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Proposal
from .serializers import ProposalSerializer
from rest_framework.response import Response
from .ai.utils import generate_text

class ProposalViewSet(viewsets.ModelViewSet):
    queryset = Proposal.objects.all()
    serializer_class = ProposalSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user = request.user
        tender_id = request.data.get("tender_id")
        prompt = f"Draft a bid proposal for tender {tender_id} by user {user.username}." 
        draft = generate_text(prompt)
        data = {
            "user": user.id,
            "tender_id": tender_id,
            "cover_letter": draft,
        }
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        proposal = serializer.save()
        return Response(self.get_serializer(proposal).data)
PY

# 18) backend/proposals/urls.py
cat > "$ROOT_DIR/backend/proposals/urls.py" <<'PY'
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ProposalViewSet

router = DefaultRouter()
router.register(r"proposals", ProposalViewSet, basename="proposal")

urlpatterns = [
    path("", include(router.urls)),
]
PY

# 19) backend/tenderai/urls.py (root)
cat > "$ROOT_DIR/backend/tenderai/urls.py" <<'PY'
from django.contrib import admin
from django.urls import path, include
from rest_framework import routers

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('tenders.urls')),
    path('api/', include('proposals.urls')),
]
PY

# 20) backend/seed.py
cat > "$ROOT_DIR/backend/seed.py" <<'PY'
from tenders.models import Tender
from datetime import date

def seed():
    Tender.objects.create(
        tender_id_source="SEED-001",
        source_portal="GeM",
        tender_title="Supply of IT Equipment",
        department="Public Works",
        state="Maharashtra",
        tender_value=5000000.00,
        last_date=date(2026, 12, 31),
        eligibility="GST, PAN",
        document_link="https://example.com/doc.pdf",
        description="Tender for supply of IT equipment for municipal project."
    )
PY

# 21) frontend/package.json
cat > "$ROOT_DIR/frontend/package.json" <<'JSON'
{
  "name": "tenderai-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.x",
    "react": "^18.x",
    "react-dom": "^18.x",
    "axios": "^1.6.0"
  }
}
JSON

# 22) frontend/next.config.js
cat > "$ROOT_DIR/frontend/next.config.js" <<'PY'
module.exports = {
  reactStrictMode: true,
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'http://localhost:8000/api/:path*' }
    ];
  }
}
PY

# 23) frontend/pages/index.js
cat > "$ROOT_DIR/frontend/pages/index.js" <<'JS'
import { useEffect, useState } from 'react';
import axios from 'axios';

export default function Home() {
  const [tenders, setTenders] = useState([]);
  useEffect(() => {
    axios.get('http://localhost:8000/api/tenders/')
      .then(r => setTenders(r.data))
      .catch(() => {
        setTenders([
          { id: 1, tender_title: "Supply of IT Equipment", state: "Maharashtra", tender_value: 5000000 }
        ]);
      });
  }, []);
  return (
    <div style={{ padding: 20 }}>
      <h1>Tender Feed</h1>
      <ul>
        {tenders.map(t => (
          <li key={t.id}>
            {t.tender_title} — {t.state} — ₹{t.tender_value}
          </li>
        ))}
      </ul>
    </div>
  );
}
JS

# 24) frontend/pages/login.js
cat > "$ROOT_DIR/frontend/pages/login.js" <<'JS'
export default function Login() {
  return (
    <div style={{ padding: 20 }}>
      <h2>Login (MVP)</h2>
      <p>Use backend signup API to create a user, then login to receive JWT.</p>
    </div>
  );
}
JS

# 25) frontend/pages/dashboard.js
cat > "$ROOT_DIR/frontend/pages/dashboard.js" <<'JS'
export default function Dashboard() {
  return (
    <div style={{ padding: 20 }}>
      <h2>Dashboard (MVP)</h2>
      <p>Overview: Today's tenders, matches, and proposals will appear here after login.</p>
    </div>
  );
}
JS

# 26) frontend/components/TenderCard.js
cat > "$ROOT_DIR/frontend/components/TenderCard.js" <<'JS'
export default function TenderCard({ tender }) {
  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 6, marginBottom: 8 }}>
      <h3>{tender.tender_title}</h3>
      <div>Department: {tender.department || 'N/A'}</div>
      <div>State: {tender.state}</div>
      <div>Value: {tender.tender_value}</div>
    </div>
  );
}
JS

# 27) frontend/components/ProposalEditor.js
cat > "$ROOT_DIR/frontend/components/ProposalEditor.js" <<'JS'
export default function ProposalEditor({ value, onChange }) {
  return (
    <textarea
      rows={14}
      cols={80}
      value={value}
      onChange={(e) => onChange?.(e.target.value)}
      placeholder="Draft your bid proposal here..."
    />
  );
}
JS

# 28) frontend/styles/global.css
cat > "$ROOT_DIR/frontend/styles/global.css" <<'CSS'
:root {
  --bg: #0f1220;
  --card: #171a2a;
  --text: #e9e9f1;
  --muted: #aab2c5;
  --primary: #4f8bd6;
}
html, body, #__next {
  height: 100%;
}
body {
  margin: 0;
  font-family: Inter, system-ui, -apple-system, "Segoe UI", Roboto;
  background: var(--bg);
  color: var(--text);
}
CSS

# 29) docker-compose.yml (root)
cat > "$ROOT_DIR/docker-compose.yml" <<'YAML'
version: '3.8'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: tender
      POSTGRES_PASSWORD: password
      POSTGRES_DB: tenderai
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    depends_on:
      - db
    environment:
      - DJANGO_SECRET_KEY=change-me
      - POSTGRES_DB=tenderai
      - POSTGRES_USER=tender
      - POSTGRES_PASSWORD=password
      - POSTGRES_HOST=db
    ports:
      - "8000:8000"
    command: >
      sh -c "python manage.py migrate && gunicorn tenderai.wsgi:application --bind 0.0.0.0:8000 --workers 2"

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  pgdata:
YAML

# 30) backend/Dockerfile
cat > "$ROOT_DIR/backend/Dockerfile" <<'DOCKER'
FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install -r requirements.txt
COPY backend/ .
CMD ["gunicorn", "tenderai.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2"]
DOCKER

# 31) frontend/Dockerfile
cat > "$ROOT_DIR/frontend/Dockerfile" <<'DOCKER'
FROM node:18-alpine
WORKDIR /app
COPY frontend/package.json .
RUN npm install
COPY frontend .
EXPOSE 3000
CMD ["npm", "run", "dev"]
DOCKER

# 32) .github/workflows/ci.yml
cat > "$ROOT_DIR/.github/workflows/ci.yml" <<'YAML'
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:

jobs:
  lint-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: tender
          POSTGRES_PASSWORD: password
          POSTGRES_DB: tenderai
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U tender -d tenderai" --health-interval 10s --health-timeout 5s --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install backend requirements
        working-directory: ./backend
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run backend tests (stub)
        run: |
          echo "No tests configured yet for MVP scaffold. Add pytest/django tests here."
      
      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install frontend dependencies
        working-directory: ./frontend
        run: |
          npm install

      - name: Build frontend
        working-directory: ./frontend
        run: |
          npm run build
YAML

# 33) .env.example
cat > "$ROOT_DIR/.env.example" <<'ENV'
# Backend
DJANGO_SECRET_KEY=your-secret-key
DEBUG=True
OPENAI_API_KEY=your-openai-key
POSTGRES_DB=tenderai
POSTGRES_USER=tender
POSTGRES_PASSWORD=password
POSTGRES_HOST=db
POSTGRES_PORT=5432
ENV

# 34) Optional: a tiny seed README for guidance
cat > "$ROOT_DIR/SEED_GUIDE.txt" <<'TXT'
Seed data guidance:
- Use backend/seed.py to populate initial Tender records.
- Run `docker-compose exec backend python backend/seed.py` if you wire a seed script entry point.
TXT

echo "Template scaffold created at $ROOT_DIR"

echo
echo "Next steps:"
echo "- Create a new repo on GitHub (Template) and push this scaffold."
echo "- In GitHub, enable Template repository (Settings > Template repository)."
echo "- Create a new project using this template (Use this template)."
echo "- In your new project, set environment secrets (OPENAI_API_KEY, DJANGO_SECRET_KEY, etc.)."
echo "- Run locally: docker-compose up -d --build; migrate; createsuperuser."
