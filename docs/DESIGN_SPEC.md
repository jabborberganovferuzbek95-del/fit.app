# FitHayot 360: dizayn spetsifikatsiyasi (agent uchun)

**Maqsad:** ilovaning ko'rinishi va harakati `docs/maket/` dagi maketga to'liq mos kelsin va ilova foydalanishga tayyor bo'lsin.
Maket: `docs/maket/00_hammasi.png` (umumiy) va 19 ta ekran `01_...` dan `19_...` gacha (har biri 2x kattalashtirilgan).

## 0. Ish tartibi (muhim)
1. **Bir vazifa = bir ekran.** Har ekran uchun mos maket rasmini oching, ilovadagi fayl bilan solishtiring, farqlarni tuzating.
2. **Tokenlardan foydalaning:** yangi rang, o'lcham va animatsiya o'ylab topmang. Hammasi `mobile/lib/ui.dart` va `mobile/lib/motion.dart` da. Yetmasa, avval shu fayllarga token qo'shing, keyin ishlating.
3. **Mavjud komponentlar:** `AppCard`, `HeroBox`, `RingProgress`, `MiniBars`, `StatTile`, `Skeleton`, `FadeSlideIn`, `PressScale`, `Loader`, `ErrorView`, `SafetyBanner`.
4. Har ekran: yorug' va qorong'i mavzu, 4 holat (yuklanish, bo'sh, xato, tayyor), matn 1.3x, kenglik 360 dp, teginish nishoni 48 dp.
5. Har vazifadan keyin: `flutter analyze` (qizil xato bo'lmasin) va ilovani qurilmada ko'ring. Server o'zgarsa `pytest -q`.
6. Qoidalar `AGENTS.md` da (terminal xavfsizligi, maxfiylik, 18+, tibbiy maslahat bermaslik).
7. Maket aniq piksel emas, ammo **joylashuv, ierarxiya, rang, radius va matnlar** mos bo'lsin. Maketdagi matnlarni (o'zbekcha) aynan ishlating.

## 1. Dizayn tizimi (maketdan olingan)
| Token | Qiymat (taxminiy, maketdan aniqlang) |
|---|---|
| Asosiy tugma | to'q yashil #0F7A3D, matn oq, balandlik 52, radius 14 |
| Qorong'i fon ustidagi tugma | yorqin yashil #6EE787, matn qora |
| Fon | oq / juda och kulrang #F6F8F6; qorong'i: #0F1512 |
| Karta | oq, radius 18-22, yengil soya (blur 10, alfa 7%) |
| Bo'lim plitkalari | och rangli fon + rangli yumaloq ikonka: Mashqlar #FDECEC/qizil, Ovqatlanish #EAF6E4/yashil, Suv #E6F1FD/ko'k, Uyqu #EFEAFB/binafsha, Meditatsiya #FCE8F3/pushti, Odatlar #FFF1DC/to'q sariq |
| Chip | tanlangan: to'q yashil fon, oq matn; tanlanmagan: och kulrang fon |
| Segmentli yorliqlar | tanlangan: to'q yashil to'ldirilgan, qolganlari kulrang fon |
| Rasmli karta | radius 20, pastki yarmida qora gradient, oq sarlavha, o'ngda oq yumaloq play tugma |
| Pastki menyu | 5 band: Bosh sahifa, Mashqlar, Ovqatlanish, Statistika, Profil; faol band yashil |
| Grafik ranglari | qadam yashil, kaloriya to'q sariq, faol vaqt binafsha, suv ko'k, uyqu indigo |
| Shrift | yumaloq geometrik sans (Manrope yoki Inter), sarlavhalar qalin (700) |
| Ikonkalar | yumaloq kvadrat plitka ichida rangli ikonka, bir xil qalinlik |

## 2. Ekranlar bo'yicha spetsifikatsiya
Holat belgilari: **TAYYOR** (kodda deyarli bor, faqat bezash), **QISMAN** (asosi bor, qismlar yetishmaydi), **YO'Q** (yangi ish kerak). Fayllar `mobile/lib/screens/` ichida.

### 01. Boshlash (hero) — `auth_screens.dart` (OnboardingScreen 1-sahifa) — QISMAN
To'liq ekranli fotosurat (sport kiyimidagi ayol, qorong'i yashil gradient). Logotip: yashil yumaloq kvadrat ichida barg ikonkasi. Sarlavha: "Sog'lom" (oq) va "Hayot" (yorqin yashil), katta qalin. Izoh: "Sog'lom tana, baxtli hayot! Har kuni yaxshiroq versiyangizga yaqinlashing." Yorqin yashil tugma "Boshlash →". Pastda "Hisobingiz bormi? **Kirish**".
*Qilinadigan ish:* fon rasmi (asset, 4.1-bo'lim), gradient, matn va tugma o'lchamlari.

### 02. Imkoniyatlar — `auth_screens.dart` (OnboardingScreen 2-sahifa) — QISMAN
**Och** fon (hozirgi variant qorong'i). Tepada meditatsiya qilayotgan ayol illyustratsiyasi barglar orasida. Sarlavha qalin: "Sog'lom hayot uchun barcha imkoniyatlar bitta ilovada". 8 qator: rangli yumaloq ikonka + matn (Mashqlar va trenirovkalar; Ovqatlanish va ratsion; Suv va suyuqlik me'yori; Uyqu va dam olish; Meditatsiya va nafas mashqlari; Sog'lom odatlar; Statistika va tahlil; Shaxsiy tavsiyalar). To'q yashil tugma "Davom etish", pastda 3 nuqtali indikator.

### 03. Hisob yaratish — `auth_screens.dart` (RegisterScreen) — QISMAN
Tepada orqaga o'q va **3 segmentli progress** (1/3). Sarlavha "Hisob yaratish", izoh "Sizning sog'lom hayotingiz shu yerdan boshlanadi!". "Google orqali davom etish" va "Apple orqali davom etish" tugmalari, "yoki" ajratgich. Maydonlar: Ism va familiya, Email manzil, Parol (ko'z ikonkasi). To'q yashil "Ro'yxatdan o'tish". Shartlar matni, "Hisobingiz bormi? **Kirish**".
*Eslatma:* Google/Apple 3.2-bo'limdagi shartlarsiz ishlamaydi; shu vaqtgacha tugmalarni yashirish yoki o'chirilgan holda "Tez orada" ko'rsatish.

### 04. Asosiy maqsad — `profile_screens.dart` (ProfileSetupScreen, 0-qadam) — QISMAN
Progress 2/3. Sarlavha "Asosiy maqsadingiz nima?". 6 ta qator: har biri rangli ikonka plitkasi + matn + o'ng chevron (Vazn tashlash, Mushak massasini oshirish, Formani saqlash, Sog'lom turmush tarzi, Stressni kamaytirish, Ko'proq energiyaga ega bo'lish). To'q yashil "Davom etish". *Ish:* har maqsadga o'z rangi (hozir hammasi yashil), tanlanganda yashil chegara.

### 05. Shaxsiy ma'lumotlar — `profile_screens.dart` — QISMAN
Progress 3/3. Jins (Erkak/Ayol segmenti), Yosh, Bo'y (sm), Vazn (kg). "Faollik darajasi": 3 kartа (Kam harakat, O'rtacha, Faol) radio-uslubda, tanlangani yashil chegarali.
*Hozir:* faqat faollik darajasi bor. *Ish:* jins/yosh/bo'y/vazn maydonlari **ixtiyoriy va aniq rozilik bilan** (`AGENTS.md`), o'tkazib yuborish tugmasi, serverda `body_profiles` jadvali va `/me/body` (3.1-bo'lim).

### 06. Bosh sahifa — `home_shell.dart` (DashboardScreen) — TAYYOR (bezash)
Tepada: avatar (rasm), "Salom, Aziza! 👋" va "Bugun ham sog'lom kun!", o'ngda qo'ng'iroq ikonkasi **qizil nuqta bilan** (o'qilmagan bildirishnoma bo'lsa). Hafta chizig'i (Du Se Ch Pa Ju Sh Ya, bugun yashil kvadrat). Katta yashil karta: chapda halqa "7 240 qadam" va "Maqsad: 10 000", o'ngda 3 qator: **masofa (km), yoqilgan kaloriya (kkal), faol vaqt (daq)**. 2x3 plitkalar: Mashqlar ("Bugungi reja"), Ovqatlanish ("Ratsion"), Suv ("1.5 / 2.5 L"), Uyqu ("7 soat"), Meditatsiya ("10 daqiqa"), Odatlar ("3 / 5").
*Ish:* masofa va kkal taxminiy hisob (bo'y/vazn rozilik bilan bo'lsa), bildirishnoma nuqtasi, plitka matnlari maketga mos, avatar rasmi (ixtiyoriy).

### 07. Mashqlar ro'yxati — `catalog_screens.dart`, `programs_screens.dart` — QISMAN
Sarlavha "Mashqlar", o'ngda qidiruv. Chiplar: Barchasi, Uyda, Zalda, Kardio, Yoga. Rasmli kartalar: "To'liq tana mashqi 20 daqiqa · Uyda · Boshlang'ich", "Kuch va massa 40 daqiqa · Zalda · O'rta", "Yoga va cho'zilish 25 daqiqa · Barcha daraja", "Kardio - yog' yoqish 30 daqiqa · O'rta daraja".
*Hozir:* 4 yorliq (Dasturlar, Uyda, Zalda, Faollik) va gradient kartalar. *Ish:* asosiy ko'rinish dasturlar ro'yxati bo'lsin (chiplar bilan), "Yoga" chipi `stretch` turiga bog'lansin, rasmlar, qidiruv. Mashqlar kutubxonasi va Active qaydi qidiruv yoki alohida kirish orqali qolsin.

### 08. Mashq dasturi — `programs_screens.dart` (ProgramDetailScreen) — QISMAN
Yuqorida katta rasm. Sarlavha, meta qatori (20 daqiqa, Oson, Uyda), izoh. "Mashqlar (8 ta)" va o'ngda "1/8". Qatorlar: kichik rasm, "1. Jumping Jacks", "45 soniya", o'ngda play. Pastda to'q yashil "Mashqni boshlash".
*Ish:* har mashq uchun kichik rasm (asset yoki `image_url`), "Oson/O'rta/Qiyin" yorlig'i, rasm va hero animatsiyasi.

### 09. Ovqatlanish — `nutrition_screens.dart` — QISMAN
O'ngda sozlamalar ikonkasi. Yorliqlar: **Retseptlar, Ratsion, Kaloriyalar**. Chiplar: Barchasi, Nonushta, Tushlik, Kechki ovqat. **2 ustunli rasmli to'r**, burchakda yurakcha (sevimli): Tovuqli salat 320 kkal · 15 daqiqa, Sabzavotli makaron 280 kkal · 20 daqiqa, Sog'lom smuzi 180 kkal · 5 daqiqa, Ovsiyali nonushta 220 kkal · 10 daqiqa.
*Hozir:* bitta ro'yxat va kaloriya kartasi. *Ish:* 3 yorliq; to'r + sevimlilar (`recipe_favorites`, `/recipes/{id}/favorite`); Ratsion yorlig'i = kunlik namuna reja (`/nutrition/plan`); Kaloriyalar yorlig'i = bugungi hisob (hozirgi kod).

### 10. Suv — `wellness_screens.dart` (WaterScreen) — TAYYOR (bezash)
Yorliqlar Bugun/Hafta/Oy. Katta ko'k halqa "1.5 L / 2.5 L", ostida minus va plyus yumaloq tugmalar. Stakanlar qatori (to'ldirilgani ko'k). Uch katak tugma: **250 ml, 500 ml, 750 ml**. Pastda ko'k karta "Suv ichish eslatmasi, Har 2 soatda" va yoqish tugmasi.
*Ish:* tezkor tugmalarni 250/500/750 qilish; eslatma kartasi (push eslatma 3.2-bo'limdagi shart bilan).

### 11. Uyqu — `wellness_screens.dart` (SleepScreen) — QISMAN
Yorliqlar Kuzatuv/Maslahatlar/Tarix. To'q ko'k-binafsha karta: oy ikonkasi, "7 soat 30 daqiqa", "Yaxshi uyqu sifati", binafsha ustunlar, vaqt (22:30 \u2013 06:00). "Uyqu bosqichlari": Chuqur uyqu, Yengil uyqu, REM uyqu, Uyg'onish + donut diagramma. "Uyqu maqsadi: Har kuni 7-8 soat uyqu" kartasi.
*Ish:* yuqoridagi karta va ustunlar (ma'lumotlar bor). **Bosqichlar (REM va h.k.) faqat soat/Health Connect ma'lumoti bo'lsa ko'rsatiladi**; bo'lmasa karta yashiriladi (soxta ma'lumot ko'rsatmang).

### 12. Meditatsiya — `meditation_screens.dart` — TAYYOR (bezash)
Chiplar: Barchasi, **Nafas**, Stress, Fokus. Katta rasmli karta "Sokin ong, baxtli hayot 10 daqiqa · Boshlang'ich" yashil play tugma bilan. "Tavsiya etilganlar" ro'yxati: kichik rasm, nom, daqiqa, play.
*Ish:* "Nafas" toifasi (bazadagi `ck_med_category` cheklovini `migrate.py` orqali yangilash), rasmlar.

### 13. Odatlar — `wellness_screens.dart` (HabitsScreen) — TAYYOR
Yorliqlar Bugungi/Haftalik/Barcha, kvadrat katakchali ro'yxat, "+ Yangi odat qo'shish" (yashil chegarali), iqtibos kartasi o'simlik ikonkasi bilan. *Ish:* faqat vizual moslash (katak shakli, bo'shliqlar).

### 14. Statistika — `stats_screen.dart` — QISMAN
Yorliqlar Hafta/Oy/Yil. 2x2 kartalar: **Qadamlar 52 340 +12%**, Kaloriyalar 2 140 +8%, Mashq vaqti 4 soat 20 daq +15%, Suv 12.5 L +10%, har birida mini ustunlar. Pastda "Vazn dinamikasi" chiziqli grafik ("58.5 kg \u22122.3 kg", Oy tanlagichi).
*Ish:* o'tgan davr bilan **foiz o'zgarishi** (`/stats` ga `change_pct`), vazn grafigi (`weight_logs`, faqat rozilik bilan; rozilik yo'q bo'lsa "Yoqish" kartasi).

### 15. Mening profilim — `profile_screens.dart` (ProfileScreen) — QISMAN
Avatar rasmi, ism, "Sog'lom hayot yo'lida 💚", tahrirlash ikonkasi. Yashil qator: Vazn / Bo'y / Yosh (agar kiritilgan bo'lsa; aks holda Seanslar / Faol kun / Seriya). Menyu: Maqsadlar, Yutuqlar, Eslatmalar, Sozlamalar, Premium (har birida kichik izoh).

### 16. Premium — `wellness_screens.dart` (PremiumScreen) — QISMAN
To'liq ekranli qorong'i fotosurat, toj ikonkasi, "Premium", "Yana ko'proq imkoniyatlar", yashil galochkali ro'yxat (1000+ mashq videolari, Shaxsiy ovqatlanish rejasi, Individual mashq dasturlari, Mutaxassis maslahatlari, Reklamasiz ilova), yorqin yashil "Premiumga o'tish", "Keyinroq".
*Hozir:* "xabar bering" ro'yxati. *Ish:* maketdagi vizual; to'lov tugmasi to'lov tizimi (3.2-bo'lim) tayyor bo'lguncha "Tez orada" holatida. Va'da qilingan narsa mavjud bo'lmasa, ro'yxatni "Rejada" deb belgilang.

### 17. AI yordamchi — `assistant_screens.dart` (CoachScreen) — QISMAN
Robot avatar, "Sizning shaxsiy sog'lom hayot maslahatchingiz", suhbat pufakchalari, tezkor javoblar: "Menga ovqatlanish rejasi tuz", "Uy sharoitida mashq dasturi ber", "Vazn tashlash uchun maslahat", "Stressni kamaytirish usullari".
*Hozir:* qoidalarga asoslangan 4 mavzu. *Ish:* maketdagi vizual va tezkor javoblar; haqiqiy AI (LLM) 3.2-bo'limdagi shartlar bilan.

### 18. Bildirishnomalar — `assistant_screens.dart` (NotificationsScreen) — QISMAN
Yorliqlar Barchasi/Tizim/Maslahatlar. Rangli ikonkali qatorlar: "Suv ichish vaqti! 10:00", "Mashq vaqti 09:00", "Yangi retsept Kecha", "Uyqu eslatmasi Kecha", "Haftalik statistika 2 kun oldin". *Ish:* har qatorda vaqt/sana, o'qilgan-o'qilmagan holati (bildirishnomalar tarixi jadvali).

### 19. Sozlamalar — `profile_screens.dart` (SettingsScreen) — QISMAN
Qatorlar: Profil ma'lumotlari, Maqsadlar, Bildirishnomalar, Ilova tili (O'zbek tili), **Qorong'i tema (yoqish tugmasi)**, Maxfiylik va xavfsizlik, Yordam va qo'llab-quvvatlash, Ilova haqida. *Ish:* tema tanlagichini oddiy yoqish tugmasiga o'zgartirish (Tizim rejimi saqlansin), ikonkalar.

## 3. Yangi imkoniyatlar (maketda bor, kodda yo'q)

### 3.1. Tashqi xizmatsiz (server + ilova, tavsiya etilgan 2-faza)
| Imkoniyat | Server | Eslatma |
|---|---|---|
| Tana ko'rsatkichlari (jins, yosh, bo'y, vazn) | jadval `body_profiles`, `PUT/GET/DELETE /me/body`; rozilik `consent_events` ga yoziladi | ixtiyoriy; eksport va o'chirishga kiradi |
| Vazn tarixi va grafik | `weight_logs`, `PUT /weight/{kun}`, `GET /weight` | faqat rozilik bilan |
| Sevimli retseptlar | `recipe_favorites`, `PUT /recipes/{id}/favorite`, `GET /recipe-favorites` | |
| Kunlik ratsion | `GET /nutrition/plan` (kaloriya maqsadiga ko'ra namuna reja) | dietolog maslahati emasligi yoziladi |
| Statistikada foiz o'zgarishi | `/stats` javobiga `change_pct` | o'tgan davr bo'sh bo'lsa N/A |
| Masofa va yoqilgan kaloriya (taxminiy) | `/dashboard/today` ga `distance_km`, `kcal_burned_est` | bo'y va vazn bo'lsa; "taxminiy" yorlig'i majburiy |
| Bildirishnomalar tarixi | jadval `notifications` (vaqt, o'qilgan) | |
| "Nafas" meditatsiya toifasi | `migrate.py` orqali CHECK cheklovini yangilash | |
| So'rovlar chegarasi, email orqali parol tiklash | `ratelimit`, `mailer` (SMTP sozlamalari) | ishlab chiqarish uchun shart |

### 3.2. Tashqi hisob, kalit yoki qurilma kerak (3-faza)
| Imkoniyat | Nima kerak | Kim qiladi |
|---|---|---|
| Fotosuratlar, mashq rasmlari/videolari | litsenziyali kontent (o'zingiz suratga olish yoki litsenziya bilan olish) | siz |
| Telefon eslatmalari (suv, mashq, ovqat, uyqu) | `flutter_local_notifications` + `timezone`; Android 13 `POST_NOTIFICATIONS` ruxsati; `build.gradle.kts` da desugaring | agent |
| Qadam sensori, uyqu bosqichlari | `pedometer` yoki Health Connect (`health`); `ACTIVITY_RECOGNITION` ruxsati; real qurilmada sinov | agent + siz (qurilma) |
| Google orqali kirish | Google Cloud'da OAuth mijoz (paket nomi va SHA-1), `google_sign_in`, serverda ID tokenni tekshirish | siz (kalit), agent (kod) |
| Apple orqali kirish | faqat iOS: Apple Developer hisobi va Mac | doiradan tashqari |
| Haqiqiy AI yordamchi | LLM provayderi hisobi va kaliti (serverda), foydalanuvchi roziligi, javob xavfsizligi qoidalari, xarajat nazorati | siz (kalit), agent (kod) |
| Premium to'lovi | Google Play Billing yoki mahalliy to'lov tizimi (Payme/Click) mijoz hisobi; serverda kvitansiyani tekshirish | siz (hisob), agent (kod) |

## 4. Rasmlar (assets)
### 4.1. Kerakli rasmlar ro'yxati
| Fayl | Joyi | O'lcham |
|---|---|---|
| `hero_welcome.jpg` | 01 hero | 1080x1920 |
| `onboarding_meditation.png` | 02 | 900x600 (shaffof fon) |
| `program_<id>.jpg` (6 ta) | 07, 08 | 1200x800 |
| `exercise_<id>.jpg` (~25 ta) | 08 kichik rasmlar | 400x400 |
| `recipe_<id>.jpg` (10 ta) | 09 | 800x600 |
| `meditation_<id>.jpg` (6 ta) | 12 | 800x600 |
| `premium_bg.jpg` | 16 | 1080x1920 |
| `avatar_default.png` | 06, 15 | 256x256 |

### 4.2. Qoidalar
- Faqat **litsenziyasi aniq** rasmlar (o'z suratlaringiz, yoki ruxsat etilgan manbalar; odam tushgan rasmlarda ruxsatnoma). Maketdagi rasmlar namuna, ularni ilovaga ko'chirmang.
- Rasmlar serverda (`image_url`, admin orqali) yoki `mobile/assets/images/` da turadi; rasm bo'lmasa gradient fon qoladi (hozirgi `HeroBox`).
- Rasm hajmi 300 KB dan oshmasin (WebP/JPG), `cacheWidth` bilan yuklansin.

## 5. Bajarish fazalari
| Faza | Mazmun | Natija |
|---|---|---|
| 1. Vizual moslash | Dizayn tokenlari, 01\u201304, 06\u201308, 10\u201314, 18\u201319 ekranlar, rasm uyalari | maketga ko'rinishda mos ilova (mavjud ma'lumotlar bilan) |
| 2. Ma'lumotli imkoniyatlar | 3.1-bo'lim: tana ko'rsatkichlari, vazn, sevimlilar, ratsion, foiz o'zgarishi, bildirishnomalar tarixi, 05, 09, 14, 15 ekranlar | to'liq funksional ekranlar |
| 3. Tashqi bog'lanishlar | 3.2-bo'lim: push, sensor, Google kirish, AI, to'lov, kontent | maketdagi barcha imkoniyatlar |
| 4. Ishlab chiqarishga tayyorlash | 6-bo'lim | foydalanuvchilarga chiqarish |

## 6. "Foydalanishga tayyor" ro'yxati
- [ ] Server HTTPS orqali ochiq manzilda, PostgreSQL, zaxira nusxa, `JWT_SECRET` va `ADMIN_PASSWORD` o'zgartirilgan, `EXPOSE_RESET_TOKEN=false`.
- [ ] SMTP orqali parol tiklash ishlaydi; so'rovlar chegarasi yoqilgan.
- [ ] Alembic migratsiyalari.
- [ ] Ilova imzolangan (release keystore), `usesCleartextTraffic` olib tashlangan (faqat HTTPS), ilova nomi va ikonka.
- [ ] Maxfiylik siyosati va foydalanish shartlari matni yozilgan va ilovada ochiladi; ma'lumot eksporti fayl sifatida beriladi.
- [ ] Mashq va retsept matnlari mutaxassis (trener, dietolog) tomonidan ko'rib chiqilgan.
- [ ] Barcha ekranlar real telefonlarda (kamida 2 xil o'lchamda) yorug' va qorong'i mavzuda sinalgan; `docs/test_protocol.md` to'ldirilgan.
- [ ] Pilot (20 foydalanuvchi) o'tkazilgan, jiddiy nuqsonlar yopilgan.
- [ ] Xatolarni kuzatish (masalan Sentry) va server loglari.
- [ ] Google Play yoki APK tarqatish uchun materiallar (skrinshotlar, tavsif).

## 7. Agentga birinchi xabar
```
AGENTS.md va docs/DESIGN_SPEC.md ni o'qi. docs/maket/ dagi rasmlar dizayn manbai.
1-faza ni bajar: avval ui.dart dagi tokenlarni maketga moslashtir (rang, radius, shrift), keyin
ekranlarni 01, 02, 03, 04, 06, 07, 08, 10, 11, 12, 13, 14, 18, 19 tartibida birma-bir qil.
Har ekrandan keyin flutter analyze ni ishga tushir va nima o'zgarganini 3 qatorda yoz.
Rasm bo'lmasa gradient fon qolsin. Hech narsani o'chirma, terminal xavfsizlik qoidasiga amal qil.
Tugatgach men bilan keyingi ekranga o'tishdan oldin skrinshot so'ra.
```
