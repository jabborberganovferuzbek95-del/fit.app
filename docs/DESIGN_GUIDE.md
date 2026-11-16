# Dizayn va harakat qo'llanmasi

## 1. Dizayn tizimi (tokenlar)
Dizaynni har ekranda qaytadan o'ylamang: bir marta qiymatlarni belgilang va hamma joyda ishlating.

| Nima | Qiymat | Qayerda |
|---|---|---|
| Asosiy rang | `kGreen` #16803C, to'q `kGreenDark` #0B3D20, aksent `kMint` #6EE787 | `ui.dart` |
| Bo'lim ranglari | Home indigo, Gym to'q sariq-qizil, Active teal, Suv ko'k, Uyqu binafsha, Ovqat yashil/to'q sariq, Meditatsiya pushti | `moduleColor`, `kindColor` |
| Masofalar | 4, 8, 12, 16, 24, 32 | hamma `EdgeInsets` |
| Radius | 12 (chip), 18 (karta), 24 (katta karta) | `AppCard`, `HeroBox` |
| Soya | juda yengil: blur 10, alfa 7% | `AppCard` |
| Matn | sarlavha 22-26 bold, bo'lim 16-18 w600, asosiy 14-15, izoh 12 | `Theme.textTheme` |

**Shrift:** bitta shrift oilasi (masalan Manrope yoki Inter). Eng ishonchli yo'l: `.ttf` fayllarni `mobile/assets/fonts/` ga qo'yish:
```yaml
flutter:
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
```
va `buildTheme` ichiga `fontFamily: 'Manrope'`. Oldin shriftda o'zbek harflari (oʻ, gʻ, tutuq belgisi) borligini tekshiring.

## 2. Ekran sifati ro'yxati (har ekran uchun)
1. Yorug' va qorong'i mavzuda ko'ring.
2. Matn kattaligi 1.3x, kenglik 360 dp.
3. To'rt holat: yuklanish (`SkeletonList` avtomatik), bo'sh (rasm/ikonka + "nima qilish kerak"), xato (`ErrorView`), tayyor.
4. Bitta asosiy harakat tugmasi (`FilledButton`), qolganlari ikkinchi darajali.
5. Bosiladigan hamma narsada teginish javobi (`InkWell` yoki `PressScale`).

## 3. Harakat (animatsiya) tamoyillari
- **Har harakat ma'no beradi:** teginishga javob, yo'nalishni ko'rsatish (nima qayerdan keldi), yutuqdan quvonch. Bezak uchun emas.
- **Davomiylik:** mayda 150-200 ms, o'rtacha 300 ms, katta 600 ms gacha. Undan uzoq foydalanuvchini kuttiradi.
- **Egri chiziq:** kirishda `easeOutCubic` (tez boshlanib yumshoq to'xtaydi), joyni almashtirishda `easeInOutCubic`.
- **Ketma-ket paydo bo'lish (stagger):** ro'yxat elementlari 50-70 ms farq bilan; 6 tadan ko'p elementga qo'llamang.
- **Ixtiyoriylik:** `MediaQuery.disableAnimations` yoqilgan bo'lsa harakat o'chadi (`reduceMotion`).
- **Unumdorlik:** uzun ro'yxatda `Opacity` va soya animatsiyasidan qoching; faqat ko'rinadigan elementlarni animatsiya qiling.

## 4. Tayyor komponentlar (`mobile/lib/motion.dart`)
| Komponent | Nima qiladi | Misol |
|---|---|---|
| `FadeSlideIn` | pastdan yumshoq paydo bo'ladi | `FadeSlideIn(delay: Duration(milliseconds: 60 * i), child: card)` |
| `CountUpText` | raqam 0 dan sanaydi | `CountUpText(value: steps, format: fmtInt, style: ...)` |
| `PressScale` | bosilganda kichrayadi | `PressScale(onTap: open, child: HeroBox(...))` |
| `Skeleton`, `SkeletonList` | yuklanish "nafas" oladi | `Loader` ichida avtomatik |
| `RingProgress` | halqa 0 dan to'ladi | allaqachon animatsiyali |
| `MiniBars` | ustunlar pastdan o'sadi | allaqachon animatsiyali |

Hozir qo'llangan joylar: bosh sahifa (qadam kartasi va bo'limlar to'ri ketma-ket paydo bo'ladi), barcha halqalar va grafiklar, yuklanish skeletlari, suv qo'shilganda haptik (titrash) javobi.

## 5. Keyingi darajadagi harakatlar (qo'shish yo'li)
**Hero o'tish** (kartadan batafsil ekranga rasm "uchib" o'tadi): ikkala ekranda bir xil `tag`:
```dart
Hero(tag: 'program-${p['id']}', child: HeroBox(...))   // ro'yxatda
Hero(tag: 'program-$programId', child: HeroBox(...))   // batafsil ekranda
```
**Qiymat o'zgarganda yumshoq almashish:**
```dart
AnimatedSwitcher(
  duration: kMed,
  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c)),
  child: Text('$count', key: ValueKey(count)),
)
```
**Maqsadga yetganda bayram (konfetti / Lottie):** yangi paket kerak (`confetti` yoki `lottie`). `pubspec.yaml` ga qo'shing,
`flutter pub get`, so'ng suv/qadam maqsadi bajarilganda bir marta ishga tushiring.
**Qadam kartasi "nafas olishi":** `AnimationController` + `ScaleTransition` bilan 1.0 dan 1.02 gacha, 3 soniyada.
**Suv to'lqini:** `CustomPainter` bilan sinus to'lqin, balandligi `total / goal`.

## 6. Antigravity (agent) bilan ishlash tartibi
1. **Bitta ekran, bitta vazifa.** Skrinshot (maket) ilovalab yozing.
2. **Tokenlardan foydalansin:** "yangi rang/o'lcham o'ylab topma, `ui.dart` va `motion.dart` dan foydalan".
3. **Tekshirish:** `flutter analyze`, so'ng `flutter run` va Hot Reload (⚡). Har ekranni yorug'/qorong'i mavzuda ko'ring.
4. Katta o'zgarishdan oldin papkaning nusxasini oling.

**Tayyor so'rovlar:**
- "Ilova ekran skrinshotini ilovaga ko'chir: `mobile/lib/screens/X.dart`. Mavjud komponentlardan foydalan, qorong'i mavzuda ham yaxshi ko'rinsin, 4 holat (yuklanish, bo'sh, xato, tayyor) bo'lsin. Oxirida `flutter analyze` ni ishga tushir."
- "Bosh sahifadagi bo'limlar to'ridagi kartalarga `PressScale` va ketma-ket paydo bo'lishni qo'sh. Animatsiyalar `reduceMotion` ni hurmat qilsin."
- "Dastur kartasidan batafsil ekranga `Hero` o'tish qo'sh (tag: `program-<id>`)."
- "Suv maqsadiga yetilganda bir martalik bayram animatsiyasini (konfetti) qo'sh. Yangi paket kerak bo'lsa avval nomini va sababini ayt."
- "Barcha ekranlarni matn 1.3x kattalikda va 360 dp kenglikda tekshirib, overflow bo'lgan joylarni tuzat."
