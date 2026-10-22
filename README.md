# O.R.O.S.: Overclocked Roguelite On Survivor
## Bedah Game & Replikasi Mekanik '20 Minutes Till Dawn' — Workshop PPLG 2026
**Mata Kuliah**: Workshop Pengembangan Perangkat Lunak dan Gim (PPLG)  
**Program Studi**: S1 Pendidikan Teknik Informatika — Fakultas Teknik, Universitas Negeri Malang  
**Dosen Pengampu**: Harits Ar Rosyid, S.T., M.T., Ph.D.  

---

### IDENTITAS ANGGOTA TIM PENGEMBANG (NAMA & NIM SAJA)

| No | Nama Lengkap | NIM | Peran Spesifik | Tanggung Jawab Utama |
|:--:|:---|:---:|:---|:---|
| **1** | **Muhammad Rayhan Najib** | `240533600012` | **Lead Programmer & Engine Integrator** | Arsitektur Godot 4.7, GDScript 2.0 static typing, twin-stick mouse aiming, sistem peluru plasma & reload, serta logika modular level-up modal. |
| **2** | **Luigy M. C. Liem Saunoah** | `240533605298` | **2D Pixel Artist, Animator & UI Designer** | Desain visual karakter Kael 4-frame run cycle, 3 jenis robot musuh (Spider, Drone, Golem), 8 ikon kartu upgrade, tileset lantai arena, dan HUD hearts/ammo. |
| **3** | **Ahmad Faizun** | `240533608123` | **Project Manager, Game Designer & QA Tester** | Manajemen sprint papan Trello, balancing kurva EXP roguelite, sintesis audio 16-bit foley (gunshot, reload, hit, death, XP ting, fanfare), dan smoke testing. |

---

### 1. HASIL BEDAH GIM REVERSE-ENGINEERING: '20 MINUTES TILL DAWN'

Berdasarkan bedah struktur biner dan pustaka kode `MinutesTillDawn_Data/Managed/Assembly-CSharp.dll` (karya Flanne), kami membedah dan mereplikasi **7 pilar mekanik utama** yang membuat *20 Minutes Till Dawn* begitu adiktif, lalu mengimplementasikannya secara presisi ke dalam Godot Engine 4.7.2:

```
+------------------------------------------------------------------------------------------------+
|                        7 PILAR MEKANIK UTAMA 20 MINUTES TILL DAWN                              |
+------------------------------------------------------------------------------------------------+
| 1. Twin-Stick Mouse Aiming    : Gerak WASD 8-arah + moncong senjata membidik bebas ke kursor.  |
| 2. Ammo & Reload Loop         : Kapasitas 6 peluru, auto-reload saat 0 atau tekan [R].         |
| 3. Firing Speed Penalty       : Kecepatan jalan berkurang 50% saat menembak/reload (kiting).   |
| 4. Atmospheric Darkness       : Arena gelap gulita, hanya disinari PointLight2D di tubuh Kael. |
| 5. Swarming Horde Spawner     : Robot merayap & melayang spawn melingkar di luar layar kamera. |
| 6. Magnetic Data Core (XP)    : Musuh mati drop XP yang tersedot magnet saat pemain mendekat.  |
| 7. Roguelite 3-Card Level-Up  : EXP penuh -> Game PAUSE -> Undian acak 3 kartu upgrade sinergi.|
+------------------------------------------------------------------------------------------------+
```

---

### 2. PERBEDAAN TEMA & ASET (100% ORIGINAL & GENERATED SENDIRI)

Meskipun secara mekanik dan *game feel* dibuat **plek ketiplek** dengan *20 Minutes Till Dawn*, seluruh aset visual, audio, latar cerita, dan antarmukanya memiliki identitas orisinal:

| Elemen | 20 Minutes Till Dawn (Asli) | O.R.O.S. (Gim Tim Kita) |
| :--- | :--- | :--- |
| **Latar & Tema** | Hutan mistis Lovecraftian bertema kegelapan gotik. | **Subterranean Foundry O.R.O.S.** — Pabrik persenjataan bawah tanah cyberpunk yang mengalami *Thermal Runaway*. |
| **Karakter Pemain** | Shana / Diamond (penyihir berbusana jubah). | **Kael (The CyberSmith)** — Teknisi pandai besi siber berjas tempur dengan visor cyan dan plasma revolver. |
| **Musuh (Enemies)** | Pohon terkutuk, laba-laba raksasa, monster mata bertentakel. | **Corrupted Defense Automations**: *Rust Spider-Bot* (melee), *Ocular Drone* (ranged shooter), *Scrap Titan* (tank mech). |
| **Gaya Audio** | Suara letusan pistol analog & efek horor berat. | **16-bit Cyber Chiptune Foley**: Revolver plasma terkompresi, dentang reload mekanik, dan bassline synthwave tempo 120 BPM. |
| **Display Anggota** | Tidak ada profil pengembang. | **Clean Text HUD & Menu**: Nama dan NIM anggota tim tertera elegan di footer HUD dan Main Menu tanpa menutupi arena. |

---

### 3. MATRIKS 8 KARTU UPGRADE ROGUELITE (LEVEL-UP CARD POOL)

Setiap kali bar EXP di bagian atas layar terisi penuh, permainan membeku (*paused*) dan pemain memilih 1 dari 3 kartu acak:

1. **OVERCLOCK CORE**: +30% Bullet Damage dan +40% gaya dorong (*knockback*) terhadap gerombolan robot.
2. **RAPID CAPACITOR**: +25% Kecepatan Tembak (*fire rate*) dan mempercepat durasi reload sebesar -20%.
3. **SPREAD EMITTER**: Menembakkan +1 proyektil tambahan per tembakan dalam formasi kipas (*multi-shot*).
4. **TUNGSTEN SHARDS**: Peluru menembus (*pierce*) +1 badan musuh tanpa langsung hancur.
5. **EXPANDED DRUM**: Menambah kapasitas magazine +3 peluru dan langsung me-reload penuh seketika.
6. **CRYO ROUNDS**: Peluru membekukan musuh saat terkena hit, memperlambat kecepatan gerak 50% selama 2.0 detik.
7. **TESLA ARC**: Benturan peluru memicu percikan petir berantai (*chain lightning*) ke 2 musuh di dekatnya.
8. **ORBITAL PLASMA SAW**: Memunculkan bilah gergaji plasma yang berputar mengelilingi badan Kael untuk mencabik musuh jarak dekat.

---

### 4. PANDUAN KONTROL & CARA MEMAINKAN (GODOT 4.7)

#### Tombol Kontrol:
* **W, A, S, D** / Panah: Berjalan 8 arah (*Catatan: Kecepatan berkurang 50% saat menembak atau me-reload peluru*).
* **Gerakan Mouse**: Membidikkan moncong senjata revolver ke segala arah secara presisi.
* **Klik Kiri Mouse**: Menembakkan peluru plasma (menghabiskan peluru di magazine).
* **Tombol R**: Me-reload peluru secara manual kapan saja.
* **Tombol R (Saat Game Over)**: Merestart permainan secara instan.

#### Cara Menjalankan di Engine:
1. Buka aplikasi **Godot Engine 4.7**.
2. Klik tombol **Import** $ightarrow$ Arahkan ke berkas: `C:/Users/WA/Documents/OROS_MicroGame/project.godot`.
3. Klik **Import & Edit**.
4. Tekan tombol **F5** pada keyboard untuk memainkan gim langsung dari Main Menu!
