# FitHayot 360: Navigatsiya va Marshrut Xaritasi

FitHayot 360 ilovasida barcha ekranlararo o'tishlar `lib/navigation.dart` dagi `AppNav` yordamchisi orqali markazlashtirilgan holda boshqariladi.

## 1. O'tish Turlari (`NavTransition`)

| Turi | Davomiylik | Egri chiziq | Maqsad va Qo'llanishi |
|---|---|---|---|
| `standard` | Tizim standarti | Standart | Standart Material platforma o'tishi |
| `fade` | 250 ms | `Curves.easeOut` | Auth va holat oqimi (Kirish, Ro'yxatdan o'tish, Parolni tiklash) |
| `sharedAxis` | 340 ms | `Curves.easeOutCubic` | Kontent va batafsil ekranlar (Dastur, Mashq, Retsept, Sozlamalar) |
| `slideUp` | 360 ms | `Curves.easeOutCubic` | Modal oqimlar (Mashg'ulot seansi, Dastur pleyeri, Seans yakuni, Maslahatchi, Bildirishnomalar, Premium) |

> [!NOTE]
> Agar foydalanuvchi tizimda yoki qurilmasida "Animatsiyalarni kamaytirish" (Reduce Motion) ni yoqqan bo'lsa, barcha o'tishlar bir lahzada (animatsiyasiz) amalga oshiriladi.

---

## 2. Asosiy Shell va Tablar (`MainShell`)

Ilova 5 ta asosiy bo'limdan iborat pastki menyuga (`NavigationBar`) ega:
1. **0: Bosh sahifa** (`DashboardScreen`) — Kunlik xulosa, qadam, suv, uyqu, meditatsiya, bugungi mashqlar.
2. **1: Mashqlar** (`CatalogScreen`) — Dasturlar, Uyda, Zalda va Faollik katalogi.
3. **2: Ovqatlanish** (`NutritionScreen`) — Kunlik kaloriyalar hisobi va toifalar bo'yicha retseptlar.
4. **3: Statistika** (`StatsScreen`) — Kunlik, haftalik va oylik ko'rsatkichlar.
5. **4: Profil** (`ProfileScreen`) — Foydalanuvchi ma'lumotlari, maqsadlar, yutuqlar va sozlamalar.

---

## 3. Ekranlar Marshrut Xaritasi

| Ekran | Kirish nuqtasi (Qayerdan ochiladi) | O'tish turi | Modal? | Orqaga qaytganda yangilanish |
|---|---|---|---|---|
| **RegisterScreen** | Onboarding / Login | `AppNav.pushFade` | Yo'q | Yangilanmaydi |
| **ForgotPasswordScreen** | Login | `AppNav.pushFade` | Yo'q | Yangilanmaydi |
| **CoachScreen** (Maslahatchi) | Bosh sahifa appBar / Profil | `AppNav.pushSlideUp` | Ha | Bosh sahifa xulosasi yangilanadi |
| **NotificationsScreen** | Bosh sahifa appBar / Profil | `AppNav.pushSlideUp` | Ha | O'qilganlik holati yangilanadi |
| **WaterScreen** | Bosh sahifa "Suv" plitkasi | `AppNav.pushSharedAxis` | Yo'q | Bosh sahifa (suv miqdori) yangilanadi |
| **SleepScreen** | Bosh sahifa "Uyqu" plitkasi | `AppNav.pushSharedAxis` | Yo'q | Bosh sahifa (uyqu daqiqasi) yangilanadi |
| **MeditationScreen** | Bosh sahifa "Meditatsiya" plitkasi | `AppNav.pushSharedAxis` | Yo'q | Bosh sahifa (meditatsiya) yangilanadi |
| **HabitsScreen** | Bosh sahifa "Odatlar" plitkasi | `AppNav.pushSharedAxis` | Yo'q | Bosh sahifa (odatlar) yangilanadi |
| **ActiveScreen** | Bosh sahifa "Faollik" tugmasi | `AppNav.pushSharedAxis` | Yo'q | Bosh sahifa (faollik) yangilanadi |
| **PlannerScreen** | Bosh sahifa "Haftalik reja" / Mashqlar appBar | `AppNav.pushSharedAxis` | Yo'q | Bugungi reja va haftalik ro'yxat yangilanadi |
| **ProgramDetailScreen** | Mashqlar (Dasturlar) / Maslahatchi tavsiyasi | `AppNav.pushSharedAxis` | Yo'q | Yangilanmaydi |
| **ExerciseDetailScreen** | Mashqlar ro'yxati (Home / Gym) | `AppNav.pushSharedAxis` | Yo'q | Yangilanmaydi |
| **RecipeDetailScreen** | Ovqatlanish / Maslahatchi tavsiyasi | `AppNav.pushSharedAxis` | Yo'q | Agar rasionga qo'shilsa kaloriyalar yangilanadi |
| **MeditationPlayer** | Meditatsiya ekrani / Hero karta | `AppNav.pushSlideUp` | Ha | Meditatsiya daqiqalari yangilanadi |
| **SessionScreen** | Bosh sahifa "Home"/"Gym", Reja bandi | `AppNav.pushSlideUp` | Ha | Bosh sahifa va statistika yangilanadi |
| **ProgramPlayer** | Dastur tafsiloti ekrani | `AppNav.pushSlideUp` | Ha | Dastur bajarilishi yangilanadi |
| **FinishScreen** | Seans yoki Dastur pleyeri oxirida | `AppNav.pushSlideUp` | Ha | Seans yopiladi, oldingi ekranlar tozalanadi |
| **GoalsScreen** | Profil menyusi / Sozlamalar | `AppNav.pushSharedAxis` | Yo'q | Profil va Bosh sahifa maqsadlari yangilanadi |
| **AchievementsScreen** | Profil menyusi | `AppNav.pushSharedAxis` | Yo'q | Yangilanmaydi |
| **PremiumScreen** | Profil menyusi | `AppNav.pushSlideUp` | Ha | Yangilanmaydi |
| **SettingsScreen** | Profil appBar / Profil menyusi | `AppNav.pushSharedAxis` | Yo'q | Sozlamalar / Profil yangilanadi |
| **EditProfileScreen** | Sozlamalar ekrani | `AppNav.pushSharedAxis` | Yo'q | Foydalanuvchi ma'lumotlari yangilanadi |

---

## 4. `pushAndRefresh` Naqshi

Ilovadagi muhim talab — ichki ekrandan qaytganda asosiy ekran ma'lumotlari qayta yuklanishi:
```dart
await AppNav.pushAndRefresh(
  context,
  const WaterScreen(),
  onReturn: reload,
  transition: NavTransition.sharedAxis,
);
```
Ushbu xatti-harakat orqali ma'lumotlar doimo dolzarb bo'lib qolishi kafolatlanadi.

