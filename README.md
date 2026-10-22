# O.R.O.S.: Overclocked Roguelite On Survivor
## Micro Game Team Intro — Workshop Pengembangan Perangkat Lunak & Gim (PPLG)
**Fakultas Teknik, Universitas Negeri Malang (2026)**  
**Dosen Pengampu**: Harits Ar Rosyid, S.T., M.T., Ph.D.

---

### IDENTITAS ANGGOTA TIM PENGEMBANG

| No | Nama Lengkap | NIM | Peran Utama | Fokus Pekerjaan |
|:--:|:---|:---:|:---|:---|
| **1** | **Muhammad Rayhan Najib** | `240533600012` | **Lead Programmer & Engine Integrator** | Arsitektur Godot 4.7, GDScript 2.0 static typing, twin-stick mouse aiming, projectile, dan logika 3-way reveal. |
| **2** | **Luigy M. C. Liem Saunoah** | `240533605298` | **2D Pixel Artist, Animator & UI Designer** | Wajah pixelate 64x64 seluruh anggota tim, sprite Kael 4-frame walk strip, 3 terminal pods, dan arena cyberpunk tileset. |
| **3** | **Ahmad Faizun** | `240533608123` | **Project Manager, Game Designer & QA Tester** | Manajemen sprint & papan Trello, perancangan GDD, audio foley chiptune 16-bit, HUD diagnostic, dan pengujian integrasi. |

---

### 1. KONSEP & GAMEPLAY RULES (MICRO SCALE)

Gim mikro ini bertindak sebagai **Prolog Resmi (Chapter 0)** dari gim utama `O.R.O.S.`. Pemain mengendalikan **Kael (The CyberSmith)** di dalam ruang reaktor bawah tanah untuk memulihkan sistem diagnostik fasilitas pabrik sebelum gerbang utama (*Blast Gate*) terbuka.

#### Mekanik Pengungkapan Anggota (3-Way Reveal Mechanics):
1. **Terminal 1: Logic Pod (Rayhan Najib)**
   * *Mekanik*: **Tembak Sasaran**.
   * Pemain mengarahkan kursor mouse dan menembak sakelar energi pod menggunakan plasma blaster.
   * Lampu pod berubah menjadi **Cyan Neon** $\rightarrow$ Muncul kartu profil lengkap Najib.
2. **Terminal 2: Vision Pod (Luigy Saunoah)**
   * *Mekanik*: **Injak Tombol Lantai (Pressure Plate)**.
   * Pemain berjalan dan menginjak sakelar medan magnet di lantai bawah.
   * Lampu pod berpendar **Magenta Neon** $\rightarrow$ Muncul kartu profil lengkap Luigy.
3. **Terminal 3: Governance Pod (Ahmad Faizun)**
   * *Mekanik*: **Interaksi Tombol [E]**.
   * Pemain mendekati terminal komando di sisi kanan hingga muncul prompt `[TEKAN E]`.
   * Pemain menekan tombol **E** $\rightarrow$ Lampu konsol menyala **Emerald Green** $\rightarrow$ Muncul kartu profil lengkap Faizun.

#### Kondisi Selesai (Victory Condition):
* Ketika diagnostik mencapai **[ 3 / 3 ] TERMINALS ONLINE**:
  * Bunyi alarm berhenti, digantikan oleh jingle kemenangan (*victory fanfare*).
  * Pintu baja raksasa (*Blast Gate*) di bagian utara arena terbuka lebar menampilkan lorong jalan keluar.
  * Tampil layar penutup berbingkai sci-fi menampilkan ketiga profil anggota tim secara berdampingan.
  * Pemain dapat menekan tombol **[R]** kapan saja untuk merestart simulasi secara instan.

---

### 2. PANDUAN KONTROL PEMAIN (INPUT MAP)

| Tombol | Fungsi Gameplay |
|:---|:---|
| **W, A, S, D** / Panah | Menggerakkan Kael (8 arah pergerakan dengan akselerasi halus) |
| **Gerakan Mouse** | Membidikkan senjata Blaster ke segala arah secara presisi |
| **Klik Kiri Mouse** | Menembakkan peluru plasma energi biru |
| **Tombol E** | Berinteraksi dengan Terminal Komando Faizun saat berada dalam jangkauan |
| **Tombol R** | Merestart simulasi dari awal |
| **Spasi / Esc** | Menutup kartu profil yang sedang aktif |

---

### 3. STRUKTUR DIREKTORI PROYEK GODOT 4.7

Proyek ditata menggunakan standar modular game development:

```text
OROS_MicroGame/
├── assets/
│   ├── audio/              # Seluruh efek suara foley 16-bit (.wav) & BGM loop
│   │   ├── bgm_oros_intro.wav
│   │   ├── sfx_activate.wav
│   │   ├── sfx_popup.wav
│   │   ├── sfx_shoot.wav
│   │   ├── sfx_step.wav
│   │   └── sfx_victory.wav
│   ├── fonts/              # Font tipografi monospace teknikal
│   │   └── tech_font.ttf
│   └── sprites/            # Aset visual pixel art berlatar transparan
│       ├── face_najib_64x64.png
│       ├── face_luigy_64x64.png
│       ├── face_faizun_64x64.png
│       ├── player_kael_idle.png
│       ├── player_kael_walk_4f.png
│       ├── spr_blaster.png
│       ├── spr_plasma_bullet.png
│       ├── pod_najib_inactive.png & pod_najib_active.png
│       ├── pod_luigy_inactive.png & pod_luigy_active.png
│       ├── pod_faizun_inactive.png & pod_faizun_active.png
│       ├── blast_gate_closed.png & blast_gate_open.png
│       └── arena_background.png
├── scenes/
│   ├── entities/           # Scene entitas modular
│   │   ├── Player.tscn
│   │   ├── Projectile.tscn
│   │   └── TerminalPod.tscn
│   ├── main/               # Scene level utama
│   │   └── MainArena.tscn
│   └── ui/                 # Scene antarmuka HUD & Victory Overlay
│       └── HUD.tscn
├── scripts/
│   ├── entities/           # Logika gerak, tembakan, dan interaksi
│   │   ├── player_controller.gd
│   │   ├── projectile.gd
│   │   └── terminal_pod.gd
│   ├── main/               # Manager alur game arena
│   │   └── main_arena.gd
│   └── ui/                 # Logika status bar, LED, dan kartu tim
│       └── hud_controller.gd
├── .gitignore              # Standar filter cache Godot 4
├── project.godot           # Konfigurasi engine (viewport 640x360, Nearest filter)
├── TRELLO_WORKFLOW.md      # Panduan alur kerja papan Trello & demonstrasi GitHub
└── README.md               # Dokumentasi teknis proyek ini
```

---

### 4. CARA MENJALANKAN PROYEK DI GODOT ENGINE

1. Buka **Godot Engine 4.7** di komputermu.
2. Klik tombol **Import** di kanan atas.
3. Arahkan (*browse*) ke folder: `C:/Users/WA/Documents/OROS_MicroGame/`.
4. Pilih file `project.godot` $\rightarrow$ Klik **Import & Edit**.
5. Tekan tombol **F5** (atau klik ikon Play di pojok kanan atas) untuk memainkan game langsung!

---

### 5. INFORMASI PENGUMPULAN TUGAS

* **Tautan Form Pengumpulan**: [Google Form PPLG Team Intro](https://forms.gle/gLGpwiZeUD3cBQV27)
* **Batas Waktu (Deadline)**: Rabu, 28 Oktober 2026
* **Ketentuan Video**:
  * Durasi video demonstrasi: 15–20 menit.
  * Disimpan di Google Drive dengan akses link **"Anyone with the link / Viewer"**.
  * Memperlihatkan alur kolaborasi layar dari perspektif masing-masing anggota (Trello $\rightarrow$ GitHub Desktop $\rightarrow$ Godot Engine).
