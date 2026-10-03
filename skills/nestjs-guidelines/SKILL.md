---
name: nestjs-guidelines
description: "Pedoman NestJS untuk modular design, dependency injection, validation, error handling, observability, security, background jobs, caching, dan pemisahan responsibility. Gunakan saat menulis, mengedit, atau me-review kode NestJS."
---

# Pedoman NestJS

Prinsip lintas stack di baseline `AGENTS.md` tetap berlaku. Skill ini menambahkan pertimbangan yang khusus untuk NestJS backend.

## Module dan Responsibility

- Gunakan module sebagai boundary dependency dan feature ownership.
- Controller menangani transport/HTTP concern; service menangani use case dan business logic; data-access abstraction menangani persistence atau external integration bila memang diperlukan.
- Jangan menumpuk business rule di controller atau decorator hanya karena secara teknis bisa dilakukan di sana.
- Gunakan dependency injection NestJS untuk dependency yang memiliki lifecycle atau dibutuhkan lintas concern.

## Request Validation

- Validasi input sedekat mungkin dengan boundary menggunakan `ValidationPipe` dan DTO.
- Pilih validation library yang konsisten dengan codebase, misalnya `class-validator`/`class-transformer` atau schema-based validation bila arsitekturnya memang menggunakannya.
- Bedakan validation error dari business rule violation dan infrastructure failure.

## Error Handling

- Gunakan exception bawaan Nest untuk HTTP concern yang sesuai dan exception/filter khusus ketika domain membutuhkan taxonomy yang lebih jelas.
- Jangan membocorkan detail database, credential, stack trace, atau internal implementation ke client.
- Preserve error context saat wrapping error dari database, network, queue, atau external service.
- Global exception handling harus menghasilkan response contract yang konsisten.

## Configuration

- Validasi environment variables saat startup.
- Pisahkan typed configuration dari pembacaan environment mentah.
- Jangan hardcode secret atau environment-specific credential ke source code.

## Logging dan Observability

- Gunakan structured logging bila application akan dikonsumsi oleh log aggregator.
- Sertakan request/correlation ID ketika tracing antar service dibutuhkan.
- Log context yang membantu diagnosis, tetapi hindari token, password, personal secret, atau payload sensitif.

## API Design

- Kontrak request/response harus explicit dan stabil.
- Gunakan API documentation tooling ketika API perlu dikonsumsi oleh client atau tim lain.
- Jangan expose persistence model secara langsung jika hal tersebut membuat perubahan schema database ikut mengubah public API.

## Security

- Terapkan authentication dan authorization di boundary yang tepat.
- Rate limiting, security headers, input validation, dan secure defaults digunakan sesuai threat model.
- Secret management dilakukan melalui environment/secret manager, bukan repository.

## Background Jobs

- Gunakan queue untuk pekerjaan asynchronous yang berat atau retryable seperti email, report generation, import/export, dan batch processing.
- Job harus idempotent atau memiliki strategi deduplication/retry yang jelas jika kemungkinan dijalankan lebih dari sekali.

## Caching

- Cache hanya ketika ada data atau operasi yang memang mendapat manfaat dari caching.
- Tetapkan TTL, invalidation, dan consistency expectations sebelum menambahkan cache.
- Jangan meng-cache data sensitif tanpa alasan dan boundary keamanan yang jelas.

## Repository/Data Access Layer

Repository abstraction bersifat kontekstual, bukan kewajiban universal.

Gunakan layer terpisah ketika:
- domain logic perlu diuji tanpa dependency database;
- terdapat beberapa data source;
- query/persistence logic cukup kompleks;
- boundary data-access perlu distabilkan terhadap perubahan ORM/storage.

Untuk CRUD sederhana, service langsung menggunakan injected data-access service dapat lebih sederhana. Jangan menambah layer hanya demi memenuhi pola arsitektur secara kosmetik.
