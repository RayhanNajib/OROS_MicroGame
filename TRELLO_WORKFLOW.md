# PANDUAN MANAJEMEN PROYEK TRELLO & GITHUB
## Micro Game Team: `O.R.O.S. (Overclocked Roguelite On Survivor)`
> **Mata Kuliah**: Workshop PPLG | **Dosen Pengampu**: Harits Ar Rosyid, S.T., M.T., Ph.D.  
> **Platform Target**: Godot Engine 4.7.2 (Stable) | **Branch Utama**: `main`

---

## 1. STRUKTUR PAPAN TRELLO (TRELLO BOARD SETUP)

* **Nama Papan (Board)**: `O.R.O.S. - Game Development Team (PPLG 2026)`
* **Anggota Tim & Peran**:
  1. **Muhammad Rayhan Najib** (`@rayhannajib`) — *Lead Programmer & Core Systems Architect*
  2. **Luigy M. C. Liem Saunoah** (`@luigysaunoah`) — *Project Manager, Level Designer & QA Lead*
  3. **M. Faizun Ni'am** (`@faizunpm`) — *2D Pixel Artist, Animator, Audio & Foley Specialist*

### A. 5 Kolom Standar Kanban (Lists):
1. **[1. BACKLOG]**: Bank ide mekanik, usulan balancing, dan backlog fitur sebelum masuk sprint aktif.
2. **[2. TO-DO]**: Kartu tugas yang sudah disepakati di sprint planning dan siap dieksekusi.
3. **[3. IN PROGRESS]**: Tugas yang sedang aktif dikerjakan di branch lokal (Maksimal 1–2 kartu per orang).
4. **[4. REVIEW & PR]**: Pekerjaan selesai di branch lokal, pull request diajukan, menunggu review dan verifikasi.
5. **[5. DONE]**: Fitur/aset lolos testing, PR di-merge ke branch `main`, dan terverifikasi di engine.

### B. Skema Label Warna (Color Labels):
* 🔴 **Merah**: `Bug / Issue / Hotfix`
* 🔵 **Biru**: `Art / Sprite / UI Asset`
* 🟢 **Hijau**: `Logic / GDScript / Engine`
* 🟡 **Kuning**: `Scene / Level Design / Arena`
* 🟣 **Ungu**: `Audio / Foley SFX & BGM`
* 🟠 **Jingga**: `Game Balance / QA / Documentation`

---

## 2. DETAIL PEMBAGIAN TUGAS & KARTU TRELLO LENGKAP

Berikut pembagian jatah tugas realistis dari awal iterasi hingga build terbaru saat ini, sehingga terlihat kontribusi merata dan terstruktur dari masing-masing anggota tim:

```
+----------------------------------------------------------------------------------------------------+
|                                    DISTRIBUSI TUGAS TIM O.R.O.S.                                    |
+------------------------------------+----------------------------------+-----------------------------+
| Muhammad Rayhan Najib (Lead Dev)   | Luigy M. C. Liem S. (PM/QA)      | M. Faizun Ni'am (Artist/Audio) |
+------------------------------------+----------------------------------+-----------------------------+
| - Engine Core & Autoloads          | - UI Tome Grimoire Modal         | - Combat Balancing & Nerf   |
| - Co-op 2P Controller & Isolasi    | - Restrukturisasi Ammo Grid 5 Kol| - Perombakan Chaos Events   |
| - Weapon Swap Debounce System      | - Reposisi Layout Icon Tome      | - Audio Procedural & SFX    |
| - Boss Scaling (3x HP & Speed)     | - Spritesheet Hero & Boss        | - Smoke Testing & QA Logs   |
| - Arena Zone & Spawner Systems     | - Campaign Wizard Co-op Modal    | - Dokumentasi & Trello Sync |
+------------------------------------+----------------------------------+-----------------------------+
```

---

### A. Jatah Kartu Luigy M. C. Liem Saunoah (Project Manager & Level Designer / QA Lead)

#### KARTU L-01: `[PM-01] Manajemen Sprint Board Trello, Backlog & Roadmap GDD OROS`
* **Member**: Luigy M. C. Liem Saunoah (`@luigysaunoah`)
* **Label**: 🟠 `Game Balance / QA / Documentation` + 🟡 `Scene / Level Design / Arena`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Inisialisasi struktur sprint board Trello (Product Backlog, Sprint To-Do, In Progress, Code Review, Done)
  - [x] Susun distribusi kartu tugas dan integrasikan tautan PR GitHub pada setiap kartu
  - [x] Perancangan alur navigasi level sektor 1-5 dan koordinasi integrasi UI Marketplace
  - [x] Quality Assurance (QA) balance testing dan pengujian stabilitas game loop
* **Branch Git**: `feature/luigy-trello-roadmap-qa` -> Pull Request #4

#### KARTU L-02: `[LVL-01] Restrukturisasi Layout Arena & Navigasi Toko Siber Marketplace`
* **Member**: Luigy M. C. Liem Saunoah (`@luigysaunoah`)
* **Label**: 🟡 `Scene / Level Design / Arena` + 🟢 `Logic / GDScript / Engine`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Rancang layout arena pabrik OROS sektor 1-5 dengan rintangan pylon dan portal
  - [x] Sempurnakan arsitektur navigasi menu toko siber (Marketplace) dan purchase verification
  - [x] Pengujian respon kontrol gamepad dan keyboard pada transisi arena
* **Branch Git**: `feature/luigy-level-marketplace-nav` -> Pull Request #6

#### KARTU L-03: `[QA-01] Validasi QA 25 Modul Game & Pengujian Balance Sektor 1-5`
* **Member**: Luigy M. C. Liem Saunoah (`@luigysaunoah`)
* **Label**: 🟠 `Game Balance / QA / Documentation`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Uji kestabilan co-op 2-player P1 (WASD) dan P2 (Numpad) tanpa konflik input
  - [x] Verifikasi formula EXP level cap 15 dan konversi SkillCore
  - [x] Dokumentasi pengujian sprint dan approval checklist video demonstrasi
* **Branch Git**: `feature/luigy-qa-balance-validation` -> Pull Request #2

---

### B. Jatah Kartu M. Faizun Ni'am (2D Pixel Artist, Animator & Audio Sound FX)

#### KARTU F-01: `[ART-01] Aset Visual 2D Pixel Art: Kael, Musuh Robot & Boss Apex`
* **Member**: M. Faizun Ni'am (`@faizunpm`)
* **Label**: 🔵 `Art / Sprite / UI Asset`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Pembuatan 2D spritesheet run-cycle Kael, Vex, dan Brutus
  - [x] Desain variasi musuh robot (Spider, Drone, Heavy Golem) dan boss apex
  - [x] Pembuatan visual efek tebasan melee, portal anomali, dan proyektil laser
* **Branch Git**: `feature/faizun-pixel-art-sprites` -> Pull Request #5

#### KARTU F-02: `[UI-01] Desain Ikon UI Siber, Frame Holografik & Kartu Upgrade`
* **Member**: M. Faizun Ni'am (`@faizunpm`)
* **Label**: 🔵 `Art / Sprite / UI Asset`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Desain frame kartu holografik Tome Grimoire dan rarity border (Legendary, Rare, Normal)
  - [x] Desain 12 ikon piksel rune upgrade dan nano-credit chip
  - [x] Sempurnakan visual HUD ammo grid dan bar status bos
* **Branch Git**: `feature/faizun-cyber-ui-cards` -> Pull Request #7

#### KARTU F-03: `[AUD-01] Desain Audio 16-Bit Chiptune Foley & Efek Suara Tempur`
* **Member**: M. Faizun Ni'am (`@faizunpm`)
* **Label**: 🟣 `Audio / Foley SFX & BGM`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Sintesis efek suara foley 16-bit (tembakan railgun, shotgun, revolver, ayunan melee, reload)
  - [x] Integrasi audio feedback hit musuh, sirene event arena, dan jingle kemenangan
  - [x] Penyetelan loop audio latar belakang BGM agar berputar kontinu tanpa henti
* **Branch Git**: `feature/faizun-audio-sfx-foley` -> Pull Request #3
  - [x] Pasang audio sirene alarm untuk Chaos Event dan suara auman spawn boss
* **Branch Git**: `feature/faizun-audio-sfx` -> Pull Request #3

#### KARTU F-04: `[QA-01] Validasi QA Co-op, Parse Error Verification & Stress Test`
* **Member**: M. Faizun Ni'am (`@faizunpm`)
* **Label**: 🔴 `Bug / Issue / Hotfix` + 🟠 `Game Balance / QA / Documentation`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Pengujian co-op 2P: pastikan Player 1 dan Player 2 memiliki skill terpisah tanpa saling tertukar
  - [x] Uji swap pisau dan senapan pada kedua keyboard/gamepad secara independen
  - [x] Lakukan smoke-testing headless Godot 4.7.2 untuk memastikan tidak ada compile/parse error
  - [x] Catat log hasil uji coba dan laporkan isu ke board Trello
* **Branch Git**: `feature/faizun-qa-testing-report` -> Pull Request #8

---

### C. Jatah Kartu Muhammad Rayhan Najib (Lead Programmer)

#### KARTU N-01: `[DEV-01] Arsitektur Singleton Autoload, GameManager & Co-Op Controller`
* **Member**: Muhammad Rayhan Najib (`@rayhannajib`)
* **Label**: 🟢 `Logic / GDScript / Engine`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Bangun fondasi arsitektur autoload (`GameManager.gd`, `GameState.gd`, `InputManager.gd`)
  - [x] Implementasi sistem Co-Op 2-Player (P1 Keyboard/Joypad 1, P2 Numpad/Joypad 2)
  - [x] Selesaikan compile error signature `update_p2_ammo_state()` pada `game_manager.gd`
  - [x] Isolasi eksekusi skill hero per-instance (`hero_type`) agar skill Kael dan Lyra tidak tertukar
* **Branch Git**: `feature/najib-core-coop-architecture` -> Pull Request #1

#### KARTU N-02: `[DEV-02] Dynamic Boss Speed Ramp-Up (3x Speed >60 Detik) & Tripled Enemy HP`
* **Member**: Muhammad Rayhan Najib (`@rayhannajib`)
* **Label**: 🟢 `Logic / GDScript / Engine` + 🟡 `Scene / Level Design / Arena`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Tingkatkan base HP seluruh musuh menjadi 3x lipat pada `enemy_base.gd`
  - [x] Program algoritma timer `boss_alive_time` pada `boss_controller.gd` dan `boss_colossus.gd`
  - [x] Buat formula ramp-up kecepatan boss hingga 3x lipat (`speed_mult` hingga 3.0x) setelah pertarungan melewati 60 detik
  - [x] Pasang batasan arena zone radius agar boss tetap bertarung di dalam perimeter
* **Branch Git**: `feature/najib-boss-speed-hp-scaling` -> Pull Request #9

#### KARTU N-03: `[DEV-03] Debounce Logic Weapon Swapping & Hotfix Script Parsing`
* **Member**: Muhammad Rayhan Najib (`@rayhannajib`)
* **Label**: 🔴 `Bug / Issue / Hotfix` + 🟢 `Logic / GDScript / Engine`
* **Status**: `DONE`
* **Checklist Tugas**:
  - [x] Perbaiki double-trigger polling input pada weapon swapping dengan variabel edge-trigger `_prev_swap_pressed`
  - [x] Pisahkan tombol switch slot P1 (`Q`, `1`, `2`) dan P2 (`Numpad 7`, `Numpad 1`, `Numpad 2`)
  - [x] Hotfix sintaks `tome_modal.gd` (perapian blok `match tome_id` pada Tome of Wind)
  - [x] Hotfix konstanta input Godot 4.7 (`KEY_RSHIFT` -> `KEY_KP_9` / `p2_skill`)
* **Branch Git**: `feature/najib-weapon-debounce-hotfix` -> Pull Request #10

---

## 3. CONTOH CHAT PEMBAGIAN TUGAS (TIM WHATSAPP / DISCORD)

Gunakan transkrip percakapan berikut sebagai bukti koordinasi tim jika dosen meminta dokumentasi chat pembagian tugas, atau bacakan saat perekaman video presentasi:

### Percakapan Sesi 1: Kickoff & Pembagian Modul Awal
> **Najib (Lead Dev)**:  
> *"Rek, sesuai pembagian tugas kemarin, aku udah beresin arsitektur dasar engine di branch `main` sama sistem co-op 2 player-nya ya. Biar pengerjaannya paralel dan gak bentrok di Git, kita bagi modul:*  
> *1. **Luigy**: Sebagai Project Manager & Level Designer, tolong koordinir sprint backlog Trello, roadmap GDD OROS, sama perancangan alur level sektor 1-5 dan navigasi Marketplace ya.*  
> *2. **Faizun**: Sebagai 2D Artist & Audio Specialist, tolong siapkan spritesheet karakter, visual musuh, desain ikon UI Tome Grimoire, sama sound effect foley 16-bit dan looping BGM ya.*  
> *Nanti bikin branch masing-masing, jangan commit langsung ke `main`."*

> **Luigy (PM/Level/QA)**:  
> *"Siap Jib, aku udah susun papan Trello lengkap dengan 5 list dan kartu tugas sprint. Aku bakal handle roadmap sektor 1-5 di `feature/luigy-trello-roadmap-qa` sekalian validasi QA balance testing-nya."*

> **Faizun (Artist/Audio)**:  
> *"Aman, aset visual piksel, UI kartu Tome, dan sound effect foley 16-bit mulai kukerjakan di branch `feature/faizun-pixel-art-sprites` dan `feature/faizun-audio-sfx-foley`. BGM homescreen juga kupastikan looping mulus."*

---

### Percakapan Sesi 2: Koordinasi Bug, Balancing & Review PR
> **Luigy (PM/Level/QA)**:  
> *"Update sprint review sore ini: Semua kartu task udah ditinjau. PR dari Faizun (Visual & Audio) sama PR arsitektur dari Najib udah dicek. Kestabilan gameplay sektor 1-5 berjalan mulus dan kartu Trello sudah siap dipindahkan ke kolom Done."*

> **Faizun (Artist/Audio)**:  
> *"Aset spritesheet 2D, ikon kartu upgrade, dan integrasi BGM intro/combat audio loop sudah clean tanpa glitch di engine."*

> **Najib (Lead Dev)**:  
> *"Mantap kolaborasinya Gi, Zun! Semua PR sudah di-merge ke branch `main`, verifikasi 25 modul automated test 100% lulus. Tinggal kita rekam video demonstrasi sesuai rundown."*

---

## 4. RUNDOWN VIDEO DEMONSTRASI (15–20 MENIT)

Gunakan struktur timeline ini saat merekam video tugas untuk Pak Harits:

| Menit | Pembicara | Agenda & Aksi di Layar |
| :--- | :--- | :--- |
| **00:00 – 02:30** | **Luigy M. C. Liem (PM)** | • Pembukaan, salam, perkenalan anggota tim & NIM.<br>• Penjelasan konsep game *O.R.O.S.* (Roguelite Survival Co-Op).<br>• Showroom papan Trello: Menunjukkan 5 list, skema label, dan distribusi kartu tugas. |
| **02:30 – 07:00** | **M. Faizun Ni'am (Artist/Audio)** | • Demo alur Git Desktop: Branch aset visual & audio.<br>• Penjelasan pembuatan spritesheet karakter 2D, musuh robot, dan frame kartu holografik.<br>• Demonstrasi aset audio foley 16-bit & loop musik latar belakang.<br>• Proses Commit, Push Origin, dan pembuatan Pull Request di GitHub. |
| **07:00 – 11:30** | **Luigy M. C. Liem (PM/QA)** | • Demo roadmap sektor 1-5 & integrasi navigasi Marketplace.<br>• Penjelasan QA checklist pengujian bug dan balance gameplay.<br>• Review Pull Request dan proses approval di web GitHub. |
| **11:30 – 16:30** | **Rayhan Najib (Lead Dev)** | • Demo merge Pull Request ke branch `main`.<br>• Buka Godot Engine 4.7.2: Tunjukkan script `GameManager.gd`, `player.gd`, dan `boss_controller.gd`.<br>• Penjelasan arsitektur Co-Op input isolation dan debounce weapon swapping.<br>• Penjelasan scaling boss 3x speed setelah 60 detik & 3x HP musuh. |
| **16:30 – 19:30** | **Seluruh Tim** | • **Live Gameplay Demo (Co-Op 2P)**: P1 (Keyboard WASD) + P2 (Numpad).<br>• Tunjukkan mekanik swap senjata pisau/senapan, aktivasi skill masing-masing hero.<br>• Tunjukkan HUD ammo 5-kolom rapi dan kemunculan Boss dengan speed ramp-up.<br>• Tunjukkan kartu Trello berpindah ke kolom `Done`. |
| **19:30 – 20:00** | **Luigy M. C. Liem (PM)** | • Kesimpulan penerapan Scrum/Kanban menggunakan Trello & GitHub.<br>• Penutupan dan salam. |

---

## 5. ATURAN INTEGRASI GIT & GITHUB (GOLDEN RULES)

1. **Selalu Fetch & Pull Sebelum Ngoding**:  
   Buka GitHub Desktop -> Tekan **`Fetch Origin`** -> Tekan **`Pull Origin`**.
2. **Dilarang Keras Direct Commit ke `main`**:  
   Semua pekerjaan wajib dibuatkan branch baru dengan format:
   * `feature/<nama>-<nama-fitur>`
   * `fix/<nama>-<nama-bug>`
3. **Pesan Commit Berstandar**:  
   Gunakan format: `[ID-KARTU] Deskripsi pekerjaan singkat dan jelas`  
   *Contoh*: `git commit -m "[UI-02] Restrukturisasi kontainer ammo menjadi grid 5 kolom"`
4. **Sematkan Trello Link di PR**:  
   Setiap membuat Pull Request di browser GitHub, cantumkan link kartu Trello terkait agar history pekerjaan terhubung rapi.
