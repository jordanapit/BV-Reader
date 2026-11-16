# BV Reader

**PDF reader and dual-monitor slide show app for Windows, built with Electron and PDF.js.**

BV Reader adalah aplikasi desktop untuk membuka file PDF dan menampilkannya sebagai **slide show**, mirip PowerPoint. Aplikasi ini mendukung dua monitor: satu monitor menampilkan slide layar penuh untuk jemaat atau penonton, monitor lainnya menampilkan **Presenter View** untuk pengendali. Tampilannya mengikuti gaya Windows 11 (WinUI 3) dan warna aksen Windows.

<!-- Tambahkan tangkapan layar di sini, misalnya:
![Tampilan utama BV Reader](docs/screenshot.png)
-->

## Fitur

**Membaca PDF**
- Buka PDF lewat tombol **Open PDF**, **seret dan lepas** (drag & drop) ke jendela aplikasi, atau langsung dari Explorer (klik dua kali atau **Open with**).
- Dua mode baca: **Continuous Scroll** dan **Single Page**. Di mode Single Page, halaman berganti dengan **scroll wheel** mouse.
- Zoom: Fit to Screen, 25%, 50%, 75%, 100%, atau ukuran bebas (10% sampai 500%).
- **Preview slide** (thumbnail) di sisi kiri. Klik untuk loncat ke halaman, dan bisa disembunyikan dengan tombol di toolbar.
- Nomor halaman di toolbar mengikuti posisi scroll.

**Slide show**
- **F5** memulai dari awal, **Shift+F5** memulai dari halaman yang sedang dipilih. Keduanya juga ada di menu tombol **Slide Show**.
- **Dua monitor:** slide layar penuh di monitor penonton, **Presenter View** (slide saat ini, slide berikutnya, dan timer) di monitor pengendali.
- **Satu monitor:** slide tampil layar penuh di monitor yang sama.
- Pilihan monitor diatur lewat dialog **Select Monitor** (tombol **Save** menyimpan, **Cancel** membatalkan).
- Transisi **Cut** (langsung) atau **Dissolve** (pudar silang yang halus, seperti Fade di PowerPoint).
- Animasi masuk ke mode slide show bergaya UWP.

**Tampilan**
- Gaya WinUI 3 dengan efek **Mica** (Windows 11) dan warna aksen yang mengikuti pengaturan Windows.
- Tema **Light**, **Dark**, atau **Use system setting** (mengikuti Windows).
- Scrollbar yang tersembunyi otomatis, spinner saat PDF dibuka, dan jendela yang langsung terbuka dalam keadaan maximized.

## Pintasan keyboard

| Tombol | Fungsi |
|---|---|
| `F5` | Mulai slide show dari awal |
| `Shift` + `F5` | Mulai slide show dari halaman ini |
| `Esc` | Keluar dari slide show, atau tutup dialog yang terbuka |
| `→` `↓` `Page Down` `Spasi` | Halaman berikutnya (saat slide show atau mode Single Page) |
| `←` `↑` `Page Up` | Halaman sebelumnya (saat slide show atau mode Single Page) |
| Scroll wheel | Ganti halaman di mode Single Page |

## Persyaratan

- **Windows 10 atau 11** (64-bit). Efek Mica dan ikon Fluent paling optimal di **Windows 11**.
- Untuk menjalankan dari kode sumber: [Node.js](https://nodejs.org) (versi LTS terbaru) dan [Git](https://git-scm.com).

## Instalasi (pengguna)

1. Unduh **BV Reader Setup** versi terbaru dari halaman [Releases](https://github.com/jordanapit/BV-Reader/releases).
2. Jalankan installer dan klik **Yes** saat Windows meminta izin Administrator.
3. Ikuti langkah installer: setujui lisensi, pilih folder instalasi (bawaan `C:\Program Files\BV Reader`), lalu pilih apakah file PDF dikaitkan dengan BV Reader dan apakah shortcut Desktop dan Start Menu dibuat.
4. Selesai. Aplikasi bisa dibuka dari Start Menu atau shortcut Desktop.

Untuk menjadikan BV Reader pembuka PDF bawaan: klik kanan sebuah PDF, pilih **Open with**, lalu **Choose another app**, pilih **BV Reader**, dan centang **Always**. Atau atur di **Settings > Apps > Default apps**.

## Menjalankan dari kode sumber

```bash
git clone https://github.com/jordanapit/BV-Reader.git
cd BV-Reader
npm install
npm start
```

Untuk langsung membuka sebuah PDF:

```bash
npm start -- "C:\path\ke\file.pdf"
```

Aplikasi hanya mengizinkan **satu jendela**. Kalau BV Reader sudah terbuka lalu Anda membuka PDF lain (dari Explorer atau perintah di atas), PDF itu dibuka di jendela yang sudah ada.

## Membuat installer

```bash
npm install
npm run dist
```

Installer dibuat dengan [electron-builder](https://www.electron.build) (target NSIS) dan hasilnya ada di folder `dist`, misalnya `dist/BV Reader Setup 1.0.0.exe`. Installer ini:

- dipasang untuk semua pengguna ke **Program Files**,
- menampilkan halaman: **Lisensi, Folder instalasi, Asosiasi PDF, Shortcut, lalu Install**,
- mendaftarkan BV Reader sebagai aplikasi PDF (opsional, sesuai pilihan di installer),
- membersihkan shortcut dan entri registry saat di-uninstall.

> Folder `dist` dan `node_modules` tidak ikut diunggah ke Git (lihat `.gitignore`). Bagikan installer lewat **Releases** di GitHub.

## Struktur proyek

| Berkas | Fungsi |
|---|---|
| `main.js` | Proses utama Electron: jendela, layar, tema, asosiasi file, satu jendela saja |
| `index.html` | Antarmuka utama: toolbar, preview slide, pembaca PDF, Presenter View |
| `presenter.html` | Jendela slide show layar penuh untuk penonton |
| `installer.nsh` | Skrip tambahan installer NSIS (halaman opsi, registry, shortcut) |
| `package.json` | Pengaturan proyek dan pengaturan pembuatan installer |
| `app-icon.ico` / `app-icon.png` | Ikon aplikasi |
| `LICENSE` / `LICENSE.txt` | Teks lisensi (GNU GPL v3) |

## Teknologi

- [Electron](https://www.electronjs.org) untuk aplikasi desktop
- [PDF.js](https://mozilla.github.io/pdf.js/) (Mozilla) untuk membaca dan menggambar PDF
- [electron-builder](https://www.electron.build) untuk membuat installer

Setiap komponen pihak ketiga tetap berada di bawah lisensinya masing-masing.

## Lisensi

BV Reader adalah perangkat lunak bebas dan sumber terbuka, dirilis di bawah **GNU General Public License versi 3** (GPL-3.0). Lihat berkas [LICENSE](LICENSE) untuk teks lengkapnya.

## Pengembang

Copyright (c) 2026 **BellaVoz Entertainment**
Developer: **JORD Andreas**
