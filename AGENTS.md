# Pedoman Umum Pengembangan Kode

Ini adalah aturan baseline yang berlaku di semua project dan semua stack. File ini adalah sumber tunggal baseline lintas stack; skill stack di bawah hanya pelengkap, bukan pengganti. Untuk aturan spesifik per stack (React, NestJS, Go, Flutter), agent akan mengonsultasi skill terpisah (`react-typescript-guidelines`, `nestjs-guidelines`, `go-gin-gorm-guidelines`, `flutter-riverpod-guidelines`) sesuai konteks task yang sedang dikerjakan.

## Prinsip Utama

- Prioritaskan **reusability** dan **composability**. Saat membuat komponen, fungsi, hook, utility, service, atau module, rancang agar dapat digunakan kembali tanpa membuat abstraksi terlalu dini.
- Utamakan solusi yang sederhana, maintainable, dan tidak _over-engineered_. Pilih implementasi paling sederhana yang tetap robust, mudah dibaca, mudah diuji, dan mudah dikembangkan.
- Jangan mengorbankan maintainability hanya untuk membuat kode terlihat lebih sophisticated.
- Ketika beberapa solusi sama-sama valid, gunakan urutan prioritas berikut:
  1. Correctness
  2. Type-safety
  3. Simplicity
  4. Maintainability
  5. Readability
  6. Performance
  7. Abstraction

## Penjelasan dan Alternatif

- Jangan hanya memberikan kode. Jelaskan secara singkat:
  - Alasan pemilihan pendekatan
  - Cara kerja bagian penting
  - Keputusan teknis yang relevan
- Jika terdapat pendekatan alternatif yang lebih baik, lebih scalable, lebih maintainable, lebih performant, atau lebih type-safe, jelaskan alternatif tersebut beserta trade-off-nya.

## Type Safety (Lintas Bahasa)

- Modelkan domain melalui type/struct/enum, bukan primitif generik (`string`, `map[string]interface{}`, `dynamic`, dsb.) ketika sebuah nilai hanya punya beberapa kemungkinan valid.
- Usahakan invalid state sulit atau bahkan tidak mungkin direpresentasikan melalui type system.
- Tangani kemungkinan nil/null/undefined secara eksplisit, jangan diasumsikan aman.
- Hindari mekanisme yang melemahkan type/compiler checking (`any`, unsafe cast, suppress warning/lint) kecuali benar-benar diperlukan dengan alasan teknis yang jelas dan dikomentari.
- Detail spesifik per bahasa (TypeScript strict mode, Go idiomatic typing, Dart null-safety) ada di skill stack masing-masing.

## Desain API dan Arsitektur

- Prioritaskan API yang predictable. Fungsi dan komponen harus memiliki:
  - Responsibility yang jelas
  - Input dan output yang mudah dipahami
  - Naming yang konsisten
  - Behavior yang tidak mengejutkan
- Terapkan separation of concerns. Pisahkan presentation, business logic, data access, validation, dan infrastructure ketika pemisahan tersebut meningkatkan maintainability dan testability.
- Prioritaskan composition dibanding inheritance atau abstraksi kompleks.
- Hindari premature abstraction. Jangan membuat abstraksi generik hanya karena dua bagian kode terlihat sedikit mirip. Lakukan abstraksi ketika pola dan kebutuhan reuse sudah jelas.
- Hindari premature optimization. Prioritaskan correctness, readability, dan maintainability sebelum optimasi performa, kecuali terdapat bottleneck yang jelas.

## Code Splitting

- Pertimbangkan pemisahan file/komponen ketika salah satu dari ini terjadi, bukan berdasarkan jumlah baris semata:
  - Sebuah file menampung lebih dari satu responsibility yang bisa dites atau di-reuse secara independen (mis. logic form, logic fetching, dan presentation tercampur dalam satu file)
  - Sebuah komponen punya lebih dari satu alasan untuk berubah (violates SRP)
  - Bagian tertentu dari file jelas akan dibutuhkan di tempat lain (bukan "mungkin nanti", tapi requirement yang sudah terlihat)
  - Ukuran file mulai menyulitkan navigasi/review meski secara logic masih satu tanggung jawab (gunakan ini sebagai sinyal sekunder, bukan alasan utama)
- Jangan split hanya demi angka baris tertentu. File panjang tapi kohesif (mis. satu reducer besar dengan banyak case yang saling terkait) boleh tetap satu file.
- Saat split, pertahankan colocation: file yang saling terkait erat (component + hook + type khusus komponen tsb) tetap dalam folder yang sama, jangan dipisah ke folder generik berdasarkan tipe file (mis. semua hooks ke `/hooks` global) kecuali memang reusable lintas fitur.
- Jelaskan alasan split (dan bukan cuma "biar rapi") setiap kali melakukan pemisahan file/komponen.

## Anti Generic/AI-pattern Design & Copywriting

Ini checklist pola yang harus dihindari, bukan proses verifikasi tambahan. Terapkan sebagai bagian dari keputusan desain/nulis saat itu juga, tanpa audit terpisah, tanpa daftar PASS/FAIL, dan tanpa harus menuliskan justifikasi tertulis untuk tiap keputusan. Bagian UI/Design berlaku untuk permukaan visual apa pun (web maupun mobile/Flutter); tidak relevan untuk kode backend murni (NestJS/Go tanpa UI).

### UI/Design — pola yang dihindari sebagai default

- Gradient biru-ungu/biru-cyan/ungu-pink sebagai warna utama, glow berwarna di background, tombol biru neon.
- Glassmorphism di banyak elemen sekaligus (navbar + card + modal + sidebar bersamaan) — kalau dipakai, maksimal 1-2 elemen sebagai aksen.
- Semua elemen dibuat pil/border-radius besar seragam (button, input, card, badge sekaligus) — variasi radius harusnya mencerminkan hierarki, bukan keseragaman otomatis.
- Shadow besar di semua komponen sampai terasa "melayang"; glow di card + button + badge + icon + background sekaligus.
- Background grid/blueprint/graph paper tanpa kaitan identitas visual produk.
- Ikon generik (sparkle, star, magic, lightning, diamond, robot, orb) sebagai ikon fitur ketika tidak relevan dengan kontennya.
- Badge kapsul "AI Powered"/"Beta"/"New" tanpa fungsi nyata, apalagi dikombinasikan dengan border tipis + glow + uppercase sekaligus.
- Ilustrasi generik (Undraw, Storyset, blob 3D) tanpa hubungan nyata ke produk.
- Layout template: Hero + 3 card fitur identik, "How It Works" selalu 3 langkah dengan lingkaran bernomor, "Trusted By" logo bar generik, footer 4 kolom Product/Company/Resources/Legal tanpa variasi — pakai struktur yang mengikuti kebutuhan konten sebenarnya.
- Palette lebih dari 2-3 warna inti + 1 aksen tanpa alasan design system yang jelas.
- Meniru tampilan produk populer (Linear, Vercel, Stripe, Notion) secara keseluruhan tanpa diminta eksplisit.

### UI/Design — yang wajib tetap benar (murah untuk dicek, jangan diskip)

- Elemen interaktif yang ditampilkan harus benar-benar berfungsi (href, onClick, submit, toggle) — kalau belum ada destination-nya, jangan render sebagai elemen final, cukup beri tanda `// TODO` + label yang terlihat, atau hilangkan.
- Navbar/link tidak boleh mengarah ke section/halaman yang tidak ada.
- Kontras teks-background mengikuti WCAG AA (jangan abu-abu tipis di atas abu-abu, jangan putih di atas gradient yang sebagian terang).
- Statistik, testimoni, atau klaim kepatuhan/keamanan tidak boleh dikarang — kalau datanya tidak tersedia, kosongkan section-nya daripada isi dengan angka/nama fiktif.

### Copywriting

- Hindari filler phrases khas AI: "In today's fast-paced world...", "It's important to note that...", "Let's dive in", "unlock the power of", buzzword seperti "AI Powered", "Seamless", "Revolutionary", "Cutting Edge", "Effortless".
- Hindari em dash sebagai jeda dramatis berulang; pakai koma, titik, atau titik dua.
- Hindari CTA generik ("Get Started", "Learn More", "Try Now") — buat spesifik ke aksi nyata ("Coba 14 Hari Gratis", "Lihat Demo").
- Untuk microcopy (button, error message, empty state, tooltip): to the point, spesifik ke konteks aplikasi, hindari template umum ("Oops! Something went wrong" tanpa detail apa yang salah).
- Untuk konten lebih panjang (landing page, dokumentasi), ikuti struktur yang sesuai logika konten, bukan template "Intro → 3 Benefit → CTA" otomatis.
- FAQ harus menjawab pertanyaan nyata terkait produk — kalau tidak tahu pertanyaan yang sering muncul, jangan bikin section FAQ template.

## Naming Conventions

- Boolean: prefix `is`, `has`, `should`, `can` (mis. `isLoading`, `hasError`, `shouldRetry`). Hindari nama ambigu seperti `flag`, `status` yang sebenarnya boolean.
- Event handler:
  - Prop yang diterima komponen (callback dari parent): prefix `on` (mis. `onSubmit`, `onClose`).
  - Function internal yang menangani event tsb: prefix `handle` (mis. `handleSubmit` yang dipanggil dari `onClick={handleSubmit}`).
- Function: gunakan kata kerja di awal yang mendeskripsikan action-nya (`fetchUser`, `calculateTotal`, `formatDate`), bukan kata benda saja.
- Array/collection: gunakan bentuk jamak atau suffix `List`/`Map`/`Set` sesuai struktur datanya (`users`, `userById` untuk Map, bukan `userData` yang ambigu soal bentuk datanya).
- Custom hook: selalu prefix `use` dan nama mendeskripsikan apa yang di-return atau side effect yang dikelola (`useDebouncedValue`, bukan `useHelper`).
- Type/interface: nama harus mendeskripsikan domain/shape-nya, hindari suffix generik yang tidak menambah informasi (`UserDataType`, `ItemInterface`) — cukup `User`, `Item`, atau lebih spesifik jika perlu disambiguasi (`UserFormValues`, `UserApiResponse`).
- Konsisten satu istilah untuk satu konsep di seluruh codebase — jangan campur `remove`/`delete`, `get`/`fetch`, `update`/`edit` untuk hal yang sama dalam satu domain.

## Edge Cases dan Error Handling

- Selalu pertimbangkan edge cases yang relevan, seperti:
  - Empty state
  - Missing data
  - Invalid input
  - Asynchronous failure
  - Duplicate request
  - Race condition
  - Cancellation
  - Kondisi batas lainnya
- Tangani error secara eksplisit. Jangan menelan error secara diam-diam.
- Bedakan validation error, recoverable error, dan system error jika konteks membutuhkannya.

## Readability dan Dependency

- Prioritaskan readability daripada cleverness. Jangan memilih kode yang lebih pendek jika membuat intent lebih sulit dipahami.
- Gunakan dependency tambahan secara selektif.
- Jangan menambahkan library jika kebutuhan dapat diselesaikan secara sederhana dan aman menggunakan native API atau dependency yang sudah tersedia.

## Asynchronous Code dan Data Fetching

Pertimbangkan kondisi berikut jika relevan (berlaku lintas stack: query database di Go/NestJS, HTTP call, atau data fetching di React/Flutter):

- Loading
- Success
- Empty
- Error
- Cancellation
- Retry
- Stale data
- Concurrency
- Race condition

## Perubahan pada Existing Codebase

- Minimalkan blast radius. Jangan melakukan refactor besar terhadap bagian yang tidak berkaitan dengan masalah yang sedang diselesaikan.
- Ikuti convention dan architecture codebase yang sudah ada selama masih masuk akal.
- Jangan memperkenalkan pattern baru tanpa manfaat yang jelas.
- Jika menemukan technical debt, code smell, atau desain yang kurang ideal, jangan hanya mengikutinya secara membabi buta. Berikan solusi yang kompatibel dengan codebase sekaligus jelaskan pendekatan yang lebih sehat jika relevan.
- Saat melakukan refactor, pertahankan existing behavior kecuali perubahan behavior memang diminta.
- Pisahkan structural refactor dari behavioral changes agar lebih mudah direview.

## Requirement dan Asumsi

- Jangan membuat asumsi requirement secara berlebihan.
- Jika terdapat ambiguity kecil, gunakan asumsi paling konservatif dan sebutkan asumsi tersebut.
- Jika ambiguity dapat mengubah architecture atau behavior secara signifikan, jelaskan bagian yang belum pasti sebelum menentukan solusi.

## Kualitas Implementasi

- Berikan solusi yang production-oriented.
- Hindari pseudo-code apabila implementasi konkret dapat diberikan.
- Pastikan kode konsisten, realistis, dan dapat dikompilasi secara masuk akal.
