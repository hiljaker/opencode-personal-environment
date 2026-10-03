---
name: go-gin-gorm-guidelines
description: "Pedoman Go dengan Gin dan GORM untuk idiomatic error handling, HTTP/service/data-access separation, context propagation, transaction safety, query correctness, dan struktur package yang terukur."
---

# Pedoman Go + Gin + GORM

Prinsip lintas stack di baseline `AGENTS.md` tetap berlaku. Skill ini menambahkan pertimbangan untuk layanan Go yang menggunakan Gin dan/atau GORM.

## Error Handling

- Gunakan `error` sebagai return value eksplisit untuk alur error normal.
- Jangan mengabaikan `error` dengan `_` kecuali nilai tersebut memang tidak relevan dan alasannya jelas.
- Wrap error dengan konteks menggunakan `%w` saat menambah informasi.
- Jangan memakai panic untuk validasi request atau kegagalan operasional yang memang dapat ditangani.

## Context Propagation

- Propagate `context.Context` melalui request chain, database operation, dan external call.
- Gunakan deadline/cancellation ketika operasi dapat berlangsung lama.
- Jangan menyimpan dependency atau mutable business state ke context hanya demi menghindari parameter eksplisit.

## Gin Handlers

- Handler fokus pada HTTP concern: parsing, validation boundary, pemanggilan use case, dan response mapping.
- Business logic tidak diletakkan di handler.
- Gunakan status code dan response contract yang konsisten.
- Jangan expose internal database model sebagai public response secara otomatis.

## Service dan Data Access

- Service menangani use case dan business rule.
- Repository/data-access menangani persistence concern ketika boundary terpisah memang memberi manfaat.
- Hindari repository wrapper yang hanya meneruskan satu method tanpa menambah abstraction value.

## GORM

- Selalu gunakan context pada operasi database.
- Waspadai N+1 query, preload yang tidak perlu, dan query list yang tidak memiliki pagination.
- Explicitly preload relation ketika relation memang dibutuhkan oleh use case.
- Hindari mengambil kolom yang tidak diperlukan untuk operasi yang sensitif terhadap bandwidth atau memory.

## Transactions

- Kelola transaction pada boundary use case yang harus atomic, bukan membuka transaction secara acak di handler.
- Pastikan rollback terjadi ketika closure mengembalikan error.
- Jangan melakukan external network call panjang di dalam database transaction kecuali consistency requirement benar-benar membutuhkannya.
- Pilih pola propagation transaction yang konsisten dan mudah ditelusuri.

## Data Modelling

- Pisahkan request/response DTO dari persistence model ketika contract API tidak identik dengan schema database.
- Gunakan pointer atau value types berdasarkan semantics, terutama ketika membedakan absent, zero value, dan null.
- Tetapkan ownership dan lifecycle untuk association/relationship dengan jelas.

## Package Structure

Gunakan struktur sederhana yang mudah dinavigasi. Contoh yang umum:

```text
cmd/
  api/
internal/
  config/
  handler/
  service/
  repository/
  model/
  dto/
  middleware/
  router/
migrations/
go.mod
```

Nama dan boundary package harus mengikuti domain serta ukuran codebase. Jangan membuat `pkg/`, `utils/`, atau package global lain hanya karena template proyek biasanya memilikinya.

## HTTP dan Reliability

- Tambahkan timeout dan limit pada operasi yang rentan memakan resource.
- Tangani pagination, filtering, sorting, dan validation secara eksplisit pada endpoint list.
- Gunakan graceful shutdown untuk service yang memiliki server atau worker.
