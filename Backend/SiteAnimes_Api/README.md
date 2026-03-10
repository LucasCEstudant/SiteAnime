# AnimeHub API 🧩

API REST para um site de animes construída com **ASP.NET Core (.NET 10)** seguindo **Clean Architecture**.

> Backend do projeto **AnimeHub** — fornece pesquisa agregada (local + provedores externos), autenticação, gerenciamento de animes e integração com serviços externos.

---

## Índice

- [Quick Start](#-quick-start)
- [Principais funcionalidades](#-principais-funcionalidades)
- [Arquitetura do projeto](#-arquitetura-do-projeto)
- [Tecnologias e integrações](#-tecnologias-e-integrações)
- [Endpoints principais (resumo)](#-endpoints-principais-resumo)
- [Rodando manualmente](#-rodando-manualmente)
- [Observabilidade e operações](#-observabilidade-e-operações)
- [Testes](#-testes)
- [Licença](#licenca)
---

## 🚀 Quick Start

A forma mais rápida de rodar o projeto é usando o script helper.

```powershell
.\start-environment.bat
```

O script automaticamente:

- valida pré-requisitos
- inicia Docker
- sobe containers necessários
- inicia a API
- executa health checks

Swagger:

```text
http://localhost:7118/swagger
```

---

## 🧩 Principais funcionalidades

### Autenticação

- JWT + Refresh Token
- Revogação de refresh tokens
- Roles `Admin` e `User`

### Gestão de usuários

- Cadastro
- Login
- Controle de permissões

### Animes (DB local)

- CRUD completo
- Informações complementares

### Pesquisa agregada

Combina resultados de:

- DB local
- Jikan (MyAnimeList)
- AniList (GraphQL)
- Kitsu (JSON API)

Filtros:

- gênero
- ano
- season
- nome

### Tradução

Endpoint:

```text
POST /api/translate
```

### Observabilidade

- logs estruturados (Serilog)
- tracing e métricas (OpenTelemetry)
- health checks

```text
/health/live
/health/ready
```

---

## 🏛 Arquitetura do projeto

O projeto segue **Clean Architecture**.

```text
src/
 ├── AnimeHub.Api
 ├── AnimeHub.Application
 ├── AnimeHub.Domain
 └── AnimeHub.Infrastructure
```

### Camadas

**Domain**

- entidades
- contratos
- regras de domínio

**Application**

- casos de uso
- DTOs
- validações

**Infrastructure**

- EF Core
- repositórios
- integrações externas

**Api**

- controllers
- middlewares

---

## 🧰 Tecnologias e integrações

### Backend

- .NET 10 / ASP.NET Core
- Entity Framework Core
- SQL Server
- JWT Authentication
- FluentValidation
- Serilog
- OpenTelemetry
- Rate Limiting
- Health Checks

### Infra

- Docker
- Docker Compose

### Integrações externas

- Jikan API
- AniList GraphQL
- Kitsu API
- LibreTranslate

---

## 📡 Endpoints principais (resumo)

### Auth

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/revoke
```

### Users

```text
GET /api/users
```

### Animes

```text
GET /api/animes
POST /api/animes
PUT /api/animes
DELETE /api/animes
```

### Busca

```text
GET /api/animes/search
GET /api/animes/filters/*
```

---

## ▶ Rodando manualmente

### Pré-requisitos

- .NET SDK 10
- Docker
- Docker Compose

### Docker

```bash
docker compose -f docker-compose.deploy.yml up -d --build
```

### Local

```powershell
dotnet run --project src/AnimeHub.Api
```

---

## 📊 Observabilidade e operações

- Health checks: `/health/live` e `/health/ready`
- Logs: Serilog
- Tracing e métricas: OpenTelemetry

---

## 🧪 Testes

```bash
dotnet test
```

Estrutura:

```text
tests/
 ├── AnimeHub.Tests.Unit
 └── AnimeHub.Tests.Integration
```

---

<a id="licenca"></a>

## ⚖️ Licença

Projeto disponibilizado apenas para fins de estudo e portfólio.

Uso comercial não permitido.
---
