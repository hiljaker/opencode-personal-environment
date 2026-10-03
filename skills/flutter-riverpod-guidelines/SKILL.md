---
name: flutter-riverpod-guidelines
description: "Pedoman Flutter + Riverpod untuk feature-first architecture, state modelling, navigation, networking, dependency management, rebuild control, dan null-safety."
---

# Pedoman Flutter + Riverpod

Prinsip lintas stack di baseline `AGENTS.md` tetap berlaku. Skill ini menambahkan pertimbangan yang khusus untuk Flutter dengan Riverpod.

## Default Stack

- Gunakan Riverpod untuk application state dan dependency graph.
- Prefer `riverpod_generator` ketika codebase memang menggunakan code generation.
- Gunakan `go_router` untuk navigation ketika routing package tersebut menjadi standar aplikasi.
- Untuk HTTP dan API clients, gunakan abstraction yang konsisten dengan codebase, misalnya Dio/Retrofit ketika keduanya memang dipakai.
- Gunakan Freezed atau sealed classes untuk immutable model dan union state ketika manfaatnya jelas.

## Feature-First Structure

Utamakan feature-first daripada mengelompokkan seluruh file berdasarkan tipe teknis di top level.

Contoh:

```text
lib/
├── core/
│   ├── network/
│   ├── router/
│   ├── di/
│   ├── theme/
│   └── utils/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           ├── pages/
│           └── widgets/
└── main.dart
```

Struktur aktual tetap boleh lebih sederhana selama boundary responsibility tetap jelas.

## Domain Layer

Domain layer bersifat opsional.

Skip ketika feature sederhana, model sudah cukup type-safe, dan tidak ada business logic yang layak diisolasi.

Gunakan ketika:
- ada business rule atau orchestration yang signifikan;
- data source perlu direkonsiliasi;
- API model perlu diterjemahkan ke domain type yang lebih ketat;
- use case membutuhkan isolation untuk testing.

Jangan membuat use case yang hanya meneruskan satu repository call tanpa menambah nilai.

## Riverpod dan State

- Modelkan state sebagai state yang coherent, bukan kumpulan boolean yang dapat saling bertentangan.
- Untuk async data, gunakan `AsyncValue` atau pola state equivalent yang jelas.
- Gunakan provider scope secara tepat agar perubahan state tidak memicu rebuild area UI yang tidak perlu.
- Gunakan `select` ketika widget hanya memerlukan sebagian kecil state dan manfaatnya nyata.
- Jangan menempatkan seluruh dependency graph aplikasi di satu file.

## Widget Design

- Pisahkan UI kecil yang benar-benar reusable dari page-level orchestration.
- Hindari widget raksasa yang sekaligus menangani layout, networking, state mutation, navigation, dan mapping data.
- Prefer composition daripada inheritance widget yang kompleks.

## Null Safety

- Perlakukan Dart null-safety sebagai bagian dari domain model, bukan hambatan yang harus dilewati.
- Hindari `!` kecuali invariant yang menjamin non-null memang kuat dan lokal.
- Tangani loading, empty, error, dan success state secara eksplisit ketika UI membutuhkannya.

## Performance

- Hindari rebuild yang luas ketika provider atau state yang lebih spesifik sudah tersedia.
- Jangan memecah widget atau menambahkan caching/memoization hanya berdasarkan asumsi performance.
- Ukur bottleneck sebelum melakukan optimasi yang menambah complexity.

## Data dan Repository

- Pisahkan mapping API/database model dari UI model ketika contract atau semantics berbeda.
- Repository boundary bermanfaat ketika data source, caching, atau testing memang memerlukannya.
- Propagate cancellation, timeout, dan network error sesuai kebutuhan user experience.
