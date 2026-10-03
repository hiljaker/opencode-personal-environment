---
name: react-typescript-guidelines
description: "Pedoman React + TypeScript untuk strict type-safety, component design, hooks, code splitting, state management, dan performance yang terukur. Gunakan saat menulis, mengedit, atau me-review kode React/TypeScript."
---

# Pedoman React + TypeScript

Prinsip lintas stack di baseline `AGENTS.md` tetap berlaku. Skill ini menambahkan pertimbangan yang khusus untuk React dan TypeScript.

## TypeScript Strictness

- Perlakukan `strict`, `strictNullChecks`, dan `noUncheckedIndexedAccess` sebagai default.
- Jangan gunakan `any` untuk melewati masalah typing.
- Hindari type assertion dan non-null assertion jika masalah dapat diselesaikan lewat type modelling, generics, narrowing, type guards, atau utility types.
- Jangan menonaktifkan compiler checking (`@ts-ignore`, `@ts-nocheck`) tanpa alasan teknis yang kuat dan terlokalisasi.
- Modelkan domain dengan tipe yang ekspresif. Gunakan discriminated union atau enum ketika domain memang memiliki himpunan state yang jelas.

## Components

- Utamakan component yang cohesive, composable, dan memiliki satu tanggung jawab yang jelas.
- Pisahkan presentational concern dari stateful atau data-fetching concern ketika pemisahan tersebut memperbaiki reuse, testability, atau readability.
- Jangan membuat abstraction hanya karena dua bagian kode terlihat mirip. Abstraksi seharusnya mengikuti pola reuse yang nyata.
- Gunakan `children` dan composition ketika itu menghasilkan API component yang lebih fleksibel daripada prop yang terus bertambah.

## Hooks dan Effects

- Custom hook harus memiliki tujuan yang jelas dan nama yang mendeskripsikan state, value, atau side effect yang dikelolanya.
- Jangan memakai `useEffect` untuk perhitungan yang bisa dilakukan langsung saat render atau untuk event yang seharusnya ditangani oleh event handler.
- Pastikan cleanup dilakukan untuk subscription, timer, listener, atau resource lain yang memiliki lifecycle.
- Hindari dependency array yang sengaja dibiarkan stale hanya untuk menghilangkan warning.

## State Management

- Letakkan state sedekat mungkin dengan consumer yang membutuhkannya.
- Pilih local state, context, atau external state berdasarkan scope dan lifecycle, bukan karena satu library selalu dipakai.
- Hindari menyimpan derived state jika value tersebut dapat dihitung dari source of truth.
- Untuk async state, modelkan loading, success, empty, dan error secara eksplisit ketika UI membutuhkannya.

## Data Fetching

- Pisahkan API/client layer dari presentational components ketika complexity mulai meningkat.
- Tangani loading, empty, error, cancellation, stale data, dan duplicate request sesuai behavior aplikasi.
- Jangan menyembunyikan kegagalan request di dalam helper yang mengubah error menjadi `undefined` tanpa kontrak yang jelas.

## Code Splitting

- Pertimbangkan `React.lazy` + `Suspense` untuk route atau component berat yang memang tidak dibutuhkan pada initial render.
- Jangan lazy-load semua component secara default.
- Split file berdasarkan responsibility, reuse yang nyata, atau boundary perubahan yang independen, bukan semata-mata jumlah baris.

## Memoization

Gunakan `useMemo`, `useCallback`, dan `React.memo` ketika terdapat alasan konkret, misalnya:
- komputasi render memang mahal dan terukur;
- referential stability dibutuhkan oleh dependency atau memoized child;
- prop identity menyebabkan rerender yang tidak perlu dan profiling mendukung perubahan tersebut.

Jangan menambahkan memoization sebagai ritual. Ia adalah optimization tool, bukan dekorasi.

## UI dan Design System

- Jika codebase memiliki design system atau wrapper components yang relevan, gunakan abstraction tersebut daripada mengulangi styling ad-hoc.
- Styling berulang dengan pilihan yang terbatas sebaiknya dimodelkan sebagai variant atau prop pada abstraction bersama.
- Inline styling dapat digunakan untuk layout glue lokal atau value yang benar-benar dinamis.
- Pastikan interactive element benar-benar bekerja, aksesibel, dan memiliki feedback untuk loading/error state yang relevan.
