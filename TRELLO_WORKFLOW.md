# PANDUAN MANAJEMEN PROYEK TRELLO & GITHUB
## Micro Game Team Intro: `O.R.O.S. (Overclocked Roguelite On Survivor)`

Dokumen ini adalah acuan resmi bagi tim pengembang untuk mendemonstrasikan integrasi alur kerja kolaboratif **Trello** dan **GitHub** pada video tugas berdurasi 15–20 menit untuk mata kuliah **Workshop PPLG** (Dosen: **Harits Ar Rosyid, S.T., M.T., Ph.D.**).

---

### 1. STRUKTUR PAPAN TRELLO (TRELLO BOARD SETUP)

* **Nama Board**: `O.R.O.S. - Game Development Team (PPLG 2026)`
* **Anggota Board**:
  1. **Muhammad Rayhan Najib** (`@rayhannajib`) — *Lead Programmer & Engine Integrator*
  2. **Luigy M. C. Liem Saunoah** (`@luigysaunoah`) — *2D Pixel Artist, Animator & UI Designer*
  3. **Ahmad Faizun** (`@faizunpm`) — *Project Manager, Game Designer & QA Tester*

#### A. 5 Kolom Standar (Lists):
1. **[1. BACKLOG]**: Bank ide dan backlog fitur yang belum dialokasikan ke sprint aktif.
2. **[2. TO-DO]**: Kartu tugas yang sudah diprioritaskan dan siap dikerjakan oleh anggota.
3. **[3. IN PROGRESS]**: Tugas yang sedang aktif dikerjakan (Maksimal 1–2 kartu per orang).
4. **[4. REVIEW & PR]**: Pekerjaan yang telah selesai di branch lokal dan membutuhkan code review / asset check sebelum di-merge ke `main`.
5. **[5. DONE]**: Fitur atau aset yang sudah lolos testing dan berhasil di-merge ke branch `main`.

#### B. Skema Label Warna (Color Labels):
* 🔴 **Merah**: `Bug / Issue`
* 🔵 **Biru**: `Art / Sprite / UI Asset`
* 🟢 **Hijau**: `Logic / GDScript / Engine`
* 🟡 **Kuning**: `Scene / Level Design`
* 🟣 **Ungu**: `Audio / Foley SFX & BGM`
* 🟠 **Jingga**: `PM / QA / Documentation`

---

### 2. DAFTAR KARTU TRELLO PER ANGGOTA

#### KARTU 1 (Tugas Luigy — 2D Pixel Artist)
* **Judul**: `[ART-01] Pembuatan Wajah Pixelate 64x64 & Spritesheet Kael`
* **Member**: Luigy M. C. Liem Saunoah
* **Label**: 🔵 `Art / Sprite / UI Asset`
* **Due Date**: 26 Oktober 2026
* **Checklist Tugas**:
  - [x] Ekspor potret wajah pixelate 64x64 Rayhan Najib (`face_najib_64x64.png`)
  - [x] Desain potret wajah pixelate 64x64 Luigy kacamata (`face_luigy_64x64.png`)
  - [x] Desain potret wajah pixelate 64x64 Faizun tactical headset (`face_faizun_64x64.png`)
  - [x] Desain karakter Kael 4-frame walk cycle 128x32 (`player_kael_walk_4f.png`)
  - [x] Desain 3 Terminal Pods (Status Inactive vs Active)
  - [x] Desain Blast Gate OROS (Status Closed vs Open)
* **GitHub Link**: Branch `feature/luigy-pixel-assets` -> Pull Request #1

#### KARTU 2 (Tugas Najib — Lead Programmer)
* **Judul**: `[DEV-01] Arsitektur Godot 4.7 & Logika 3-Way Reveal Terminal`
* **Member**: Muhammad Rayhan Najib
* **Label**: 🟢 `Logic / GDScript / Engine` + 🟡 `Scene / Level Design`
* **Due Date**: 27 Oktober 2026
* **Checklist Tugas**:
  - [x] Inisialisasi proyek Godot 4.7.2 (`project.godot`, viewport 640x360, Nearest filter)
  - [x] Program kontroler gerak 8-arah WASD Kael (`player_controller.gd`)
  - [x] Program twin-stick aiming mouse & penembak plasma blaster (`projectile.gd`)
  - [x] Program Terminal Pod logika 3 aksi: Tembak (Najib), Injak (Luigy), dan Tekan E (Faizun)
  - [x] Hubungkan signal `pod_activated` ke scene manager `MainArena.gd`
* **GitHub Link**: Branch `feature/najib-engine-logic` -> Pull Request #2

#### KARTU 3 (Tugas Faizun — PM & QA Tester)
* **Judul**: `[QA-01] Integrasi Audio 16-Bit, HUD Diagnostik & Pengujian Bug`
* **Member**: Ahmad Faizun
* **Label**: 🟣 `Audio / Foley SFX & BGM` + 🟠 `PM / QA / Documentation`
* **Due Date**: 28 Oktober 2026
* **Checklist Tugas**:
  - [x] Buat & impor 5 SFX foley 16-bit (`sfx_shoot`, `sfx_activate`, `sfx_step`, `sfx_popup`, `sfx_victory`)
  - [x] Buat & impor musik tema synth ambient loop (`bgm_oros_intro.wav`)
  - [x] Desain panel HUD popup kartu anggota tim (Nama, NIM, Foto 64x64)
  - [x] Desain layar kemenangan akhir (Victory Screen 3 kartu berdampingan)
  - [x] Lakukan smoke testing: pastikan gate membuka saat 3/3 terminal aktif
* **GitHub Link**: Branch `feature/faizun-qa-balancing` -> Pull Request #3

---

### 3. PANDUAN PRAKTIK SIKLUS GITHUB (15–20 MENIT VIDEO)

Sesuai arahan Pak Harits di video kuliah:
1. **Sebelum mulai**: Selalu buka GitHub Desktop $\rightarrow$ tekan **`Fetch Origin`** (atau **`Pull Origin`**).
2. **Aturan Utama**: **Dilarang keras commit langsung ke `main`**.
3. **Pola Kerja**:
   * Ambil kartu di Trello $\rightarrow$ Pindahkan ke `In Progress`.
   * Di GitHub Desktop: Buat branch baru dari `main` dengan nama fitur (contoh: `feature/luigy-pixel-assets`).
   * Buka software kerja (Aseprite / Godot Engine) $\rightarrow$ kerjakan tugas $\rightarrow$ Simpan (Ctrl + S).
   * Buka GitHub Desktop $\rightarrow$ Tulis summary commit yang jelas $\rightarrow$ Klik `Commit to <branch>` $\rightarrow$ Klik `Publish Branch` / `Push Origin`.
   * Buka GitHub di Browser $\rightarrow$ Klik `Create Pull Request`.
   * Pindahkan kartu Trello ke kolom `Review & PR` $\rightarrow$ Sematkan link PR di kartu Trello.
   * Rekan tim mereview PR $\rightarrow$ Klik `Merge Pull Request` $\rightarrow$ Konfirmasi merge.
   * Di Trello: Pindahkan kartu ke kolom `Done`.
   * Anggota tim lain kembali ke GitHub Desktop $\rightarrow$ Switch ke `main` $\rightarrow$ Klik `Fetch & Pull Origin`.
