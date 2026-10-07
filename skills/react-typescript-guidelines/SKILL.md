---
name: react-typescript-guidelines
description: "Pedoman React + TypeScript untuk strict type-safety, component design, hooks, state management, form handling, data fetching, routing dan code splitting, serta performance yang terukur. Gunakan saat menulis, mengedit, atau me-review kode React/TypeScript."
---

# Pedoman React + TypeScript

Prinsip lintas stack di baseline `AGENTS.md` tetap berlaku. Skill ini menambahkan pertimbangan yang khusus untuk React dan TypeScript.

## TypeScript Strictness

- Aktifkan `strict` (sudah mencakup `strictNullChecks`) dan `noUncheckedIndexedAccess` sebagai default; pertimbangkan `exactOptionalPropertyTypes` bila codebase siap.
- Jadikan `tsc --noEmit` dan lint TypeScript/React (mis. `@typescript-eslint/no-floating-promises`, `react-hooks/exhaustive-deps`) sebagai gate di CI, bukan hanya konvensi.
- Jangan gunakan `any` untuk melewati masalah typing.
- Hindari type assertion dan non-null assertion jika masalah dapat diselesaikan lewat type modelling, generics, narrowing, type guards, atau utility types.
- Jangan menonaktifkan compiler checking (`@ts-ignore`, `@ts-nocheck`) tanpa alasan teknis yang kuat dan terlokalisasi.
- Modelkan domain dengan tipe yang ekspresif. Gunakan discriminated union atau enum ketika domain memang memiliki himpunan state yang jelas.
- Gunakan `satisfies` ketika nilai harus valid terhadap tipe tetapi literal/inference-nya tetap dipertahankan; jangan menggantinya dengan cast `as`.
- Pastikan `switch` atas discriminated union bersifat exhaustive: gunakan fallback `assertNever(value: never)` agar varian baru memaksa compiler menandai semua tempat yang belum menanganinya.
- Modelkan props yang saling eksklusif sebagai discriminated union, bukan tumpukan boolean opsional, mis. `{ variant: "link"; href: string } | { variant: "button"; onClick: () => void }`; kombinasi tidak valid sebaiknya tidak dapat direpresentasikan.
- Untuk wrapper komponen, ambil tipe props dari komponen dasarnya (`ComponentPropsWithoutRef`/`ComponentPropsWithRef`) alih-alih menulis ulang daftar props yang cepat drift.
- Turunkan tipe dari kontrak runtime di boundary (schema validasi, response parser) ketika tersedia; hindari tipe paralel yang harus dijaga selaras secara manual.
- Pertimbangkan branded type hanya untuk identifier yang berisiko tertukar; jangan menambah ceremony bila jenisnya tunggal.

## Components

- Utamakan component yang cohesive, composable, dan memiliki satu tanggung jawab yang jelas.
- Pisahkan state/data-fetching dari presentational concern hanya ketika pemisahan itu memberi reuse, testability, atau kejelasan nyata; jangan menerapkan pola container/presentational secara default, dan jangan memecah komponen yang cohesive demi "separasi".
- Jangan membuat wrapper component atau custom hook yang hanya meneruskan props/parameter tanpa menambah kontrak, validasi, atau konsistensi.
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
- Untuk async state, gunakan satu value yang tidak memungkinkan kombinasi kontradiktif (mis. discriminated union dengan `status`), bukan flag terpisah seperti `isLoading` + `error` + `data`.

Contoh model state yang exhaustive:

```tsx
type AsyncState<T> =
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "empty" }
  | { status: "success"; data: T };

function assertNever(value: never): never {
  throw new Error(`Unhandled state: ${String(value)}`);
}

function ItemView({ state }: { state: AsyncState<Item[]> }) {
  switch (state.status) {
    case "loading":
      return <Spinner />;
    case "error":
      return <ErrorNotice error={state.error} />;
    case "empty":
      return <EmptyState />;
    case "success":
      return <ItemList items={state.data} />;
    default:
      return assertNever(state);
  }
}
```

## Data Fetching

- Pisahkan API/client layer dari presentational components ketika complexity mulai meningkat.
- Saat parameter berubah, batalkan atau abaikan response lama (race condition), dan dedupe request identik; gunakan mekanisme cancellation dari library/framework yang dipakai, bukan flag manual yang mudah bocor.
- Jangan menyembunyikan kegagalan request di dalam helper yang mengubah error menjadi `undefined` tanpa kontrak yang jelas.

## Form

- Tetapkan satu sumber kebenaran validasi (schema/kontrak di boundary), lalu turunkan tipe dari sana; jangan menulis aturan yang sama berulang di handler submit, validator manual, dan definisi tipe terpisah.
- Pilih controlled atau uncontrolled secara sadar: controlled ketika value perlu direaksikan saat render (field saling bergantung, format saat mengetik), uncontrolled/ref ketika tidak, agar input tidak memicu rerender yang tidak perlu.
- Modelkan proses submit sebagai state eksplisit (`idle`/`submitting`/`success`/`error`), cegah double submit, dan pastikan input tetap dapat diperbaiki setelah error tanpa kehilangan isian.
- Tampilkan error validasi field di dekat field-nya; error sistem (network/server) sebagai feedback level form. Jangan menyeragamkan semua kegagalan menjadi pesan generik di field pertama.
- Validasi client adalah untuk UX, bukan pengganti validasi server; menonaktifkan tombol submit bukan satu-satunya pertahanan terhadap input tidak valid.
- Jika form memang kompleks, gunakan library form/schema yang menjadi standar codebase (mis. React Hook Form + Zod) alih-alih membangun ulang state form manual; jangan menambah library baru untuk form satu field.

## Code Splitting dan Routing

- Prioritaskan pemisahan di level route melalui mekanisme router/framework yang dipakai (lazy route module) sebelum memecah komponen individual.
- Lazy-load hanya komponen berat yang benar-benar tidak dibutuhkan pada render pertama; jangan lazy-load komponen yang selalu terlihat atau dibutuhkan untuk layout yang stabil.
- Perhatikan batasan `React.lazy`: hanya menerima default export, named export perlu remap eksplisit, dan setiap batas lazy memerlukan `Suspense` fallback yang sesuai konteks.
- Pertimbangkan prefetch untuk route yang paling mungkin dikunjungi berikutnya, bukan membebani bundle awal.
- Jangan lazy-load semua component secara default.
- Colocate komponen dengan hook dan tipe yang hanya dipakainya; jangan membuat folder global (`/hooks`, `/types`) untuk sesuatu yang belum terbukti reusable lintas fitur.

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
