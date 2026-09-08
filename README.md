# VexxuzzZx HUB

Versi UI ungu glassmorphism dengan branding VexxuzzZx dan Bahasa Indonesia.

## Isi
- `loader.lua` — loader + UI notifikasi/panel.
- `script.lua` — panel utama dan sistem konfigurasi yang ada pada proyek asal.
- `ronneiprime.lua` — modul tambahan dari proyek asal, hanya direbranding.
- `MADEEvolveSansEVO.ttf` — font utama; loader akan memakai `getcustomasset` jika executor mendukungnya dan otomatis fallback ke Gotham jika tidak.

## Catatan fungsi
Fungsi yang bergantung pada game, executor, RemoteEvent/RemoteFunction, atau perubahan server tetap mengikuti implementasi proyek asal. Tidak ada jaminan semua fungsi dapat bekerja pada setiap game Roblox.

## Instalasi
1. Letakkan `MADEEvolveSansEVO.ttf` satu folder dengan script jika ingin mencoba custom font.
2. Jalankan `loader.lua` pada lingkungan yang memang mendukung API yang dipakai proyek.
3. Jika custom font tidak tersedia, UI otomatis memakai font fallback bawaan Roblox.
