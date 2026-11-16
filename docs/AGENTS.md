# FitHayot 360: agent yo'riqnomasi (Antigravity va boshqa agentlar uchun)

## Maqsad
Sog'lom hayot ilovalari orasida eng yaxshilaridan biri darajasida **chiroyli, silliq va ishonchli** mahsulot yaratish.
Funksiya to'liqligi, ko'rinish sifati va harakat (animatsiya) tengma-teng muhim.

## Loyiha
Home/Gym/Active mashg'ulotlari, dasturlar, ovqatlanish, suv, uyqu, qadam, meditatsiya, odatlar, statistika va yutuqlar bitta ilovada.
- Server: `backend/` FastAPI + SQLAlchemy + PostgreSQL (yangi jadval: `app/models.py`, yangi ustun: `app/migrate.py`, kontent: `app/seed.py`)
- Mobil: `mobile/` Flutter + Provider + http. Rang va komponentlar `lib/ui.dart`, harakat `lib/motion.dart`
- Foydalanuvchiga ko'rinadigan barcha matn **o'zbekcha** (lotin).

## Mahsulot qoidalari (yangilangan)
**Ruxsat etiladi (talab qilingan holda):**
- **Sun'iy intellekt**: ruxsat. Faqat **server orqali** chaqiriladi (API kaliti ilovaga yoki gitga tushmaydi, `.env` da turadi),
  ixtiyoriy, "AI" deb aniq belgilanadi, yuboriladigan ma'lumot minimal bo'ladi. Hozirgi `/coach/ask` qoidaga asoslangan; AI qo'shilsa alohida endpoint.
- **Tana ko'rsatkichlari** (yosh, jins, bo'y, vazn): ruxsat, lekin **ixtiyoriy**, tushunarli matn va aniq rozilik bilan (`consent_events` ga yoziladi),
  o'tkazib yuborish mumkin, eksport va o'chirishga kiradi, hech qachon uchinchi tomonga sotilmaydi. AIga faqat alohida roziligi bilan.
- **GPS/sensor** (masalan, qadam sanagich): faqat tizim ruxsati so'ralgandan keyin, ixtiyoriy.

**O'zgarmaydi (foydalanuvchini himoya qiladi):**
- Ilova **18+** uchun.
- **Tashxis qo'ymaydi, davolash va dori tavsiya qilmaydi.** Xavfli tavsiya yo'q: haddan tashqari kam kaloriya, tez vazn tashlash va'dalari,
  vazn/ovqat bo'yicha ovqatlanish buzilishiga olib kelishi mumkin bo'lgan matnlar yozilmaydi. Mos joyda ogohlantirish ko'rsatiladi.
- **Kasallik, tashxis va dori ma'lumotlari yig'ilmaydi** (eng sezgir ma'lumot).
- Har foydalanuvchi **faqat o'z ma'lumotiga** ega (begona resurs uchun 404). Parol hech qachon qaytarilmaydi.
- Yangi turdagi ma'lumot qo'shilsa: modelga, `/me/export` ga va hisobni o'chirishga qo'shiladi, maxfiylik matni yangilanadi.

## Dizayn va harakat qoidalari
To'liq: `docs/DESIGN_GUIDE.md`. Qisqacha:
- Material 3, 8 pt to'r, kartalar radiusi 18, rang faqat `ui.dart` tokenlaridan. **Har ekran yorug' va qorong'i mavzuda** tekshiriladi.
- Har ekranda 4 holat: yuklanish (skelet), bo'sh, xato (qayta urinish), tayyor.
- Harakat: 150-650 ms, `easeOutCubic`, ketma-ket paydo bo'lish qadami 50-70 ms. `reduceMotion` hurmat qilinadi. Faqat `motion.dart` komponentlari.
- Teginish nishoni kamida 48 dp, matn kontrasti 4.5:1, matn kattalashtirilganda (1.3x) ekran buzilmasin, 360 dp kenglikda ham sig'sin.
- Yangi ekran qo'shilsa: mavjud komponentlar (`AppCard`, `RingProgress`, `HeroBox`, `StatTile`, `MiniBars`) qayta ishlatiladi.

## Texnik qoidalar
- Server o'zgarsa: `cd backend && pytest -q` hammasi o'tishi shart. Yangi funksiyaga test yoziladi.
- Ilova o'zgarsa: `cd mobile && flutter analyze` da `error` bo'lmasin.
- Yangi paket kerak bo'lsa: avval nima uchun kerakligini yozib ber, so'ng `pubspec.yaml` ga qo'sh.
- Katta o'zgarishdan oldin reja yoz; ma'lumot bazasi sxemasini buzma (faqat nullable ustun qo'shish, `migrate.py` orqali).

## Terminal xavfsizligi (o'zgarmaydi)
`docker rm`, `docker volume rm`, `docker compose down -v`, `rm -rf` va shunga o'xshash o'chiruvchi buyruqlarni **mendan so'ramasdan bajarma**.
Boshqa konteynerlarga tegma (faqat shu loyihaning `docker compose` xizmatlari). `docker ps -aq` bilan hammasini o'chirma.
