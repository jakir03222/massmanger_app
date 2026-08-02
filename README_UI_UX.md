# Mass Manager — App Features

**Mass Manager / ম্যাস ম্যানেজার**  
Tagline: Mess accounts, made easy / মেসের হিসাব, সহজে  

Shared mess (বোর্ডিং / স্টুডেন্ট মেস) accounting app। Bangla + English। Currency: BDT (টাকা)। Phone-first (Android + iOS)।

একটা mess-এ সবাই একসাথে meal, bazaar, bill আর month-end হিসাব track করে।

---

## 1. Auth & onboarding

| Feature | Description |
|---------|-------------|
| **Splash** | App খোলার সময় brand logo + loading দেখায়। |
| **Onboarding (4 pages)** | প্রথমবারে meal, bazaar, report, join-code বুঝিয়ে দেয়। Skip / Next / Get started। |
| **Google Sign-In** | এক ট্যাপে Google দিয়ে login (Android / Web)। iOS-এ লুকানো। |
| **Email login** | Email + password দিয়ে login। |
| **Register** | নাম, email, password দিয়ে নতুন account। |
| **Forgot password** | Email-এ password reset link পাঠায়। |
| **Language switch** | Login-এর আগেই Bangla / English বদলানো যায়। |
| **Idle auto logout** | ~30 মিনিট idle থাকলে automatically sign-out। |

---

## 2. Mess setup

| Feature | Description |
|---------|-------------|
| **Create mess** | Mess name + location দিয়ে নতুন mess তৈরি। creator হয়ে যায় **Super Admin**। |
| **Join mess** | 6-digit code দিয়ে existing mess-এ join (Member হিসেবে)। |
| **Invite code** | Create-এর পর code copy / share করা যায় যাতে অন্যরা join করতে পারে। |

---

## 3. Roles

| Role | Description |
|------|-------------|
| **Super Admin** | Mess owner। Admin promote/demote, ownership transfer, email দিয়ে member add, সব manage। |
| **Admin** | Meal / bazaar / schedule / swap approve করে। Bill, payment mark, month lock, PDF export করতে পারে। |
| **Member** | Meal / bazaar / date / swap **request** পাঠায়। নিজের balance দেখে। Approved shared data দেখে। |

---

## 4. Home (dashboard)

মূল overview screen — Admin আর Member আলাদা জিনিস দেখে।

| Feature | Description |
|---------|-------------|
| **Hero card** | Mess name, location, user name, role badge, current month, notification bell (unread count)। |
| **Quick actions** | Meals, Bazaar dates, Notifications, Report-এ দ্রুত যাওয়া। |
| **Today snapshot** | আজকের meal count, spend; Admin-এর জন্য meal rate। |
| **Month navigator** | Previous / next month ঘোরা। Closed month-এ lock badge। |
| **Stats grid** | Monthly meals, market total, meal rate, bills, due bazaar, member count, today stats। |
| **Smart PDF** *(Admin)* | পুরো month-এর statement PDF download / share। |
| **Month-close pack** *(Admin)* | Report + payment একসাথে shareable pack। |
| **Bills shortcut** *(Admin)* | Mess bills screen-এ যাওয়া। |
| **Member summary** *(Admin)* | প্রত্যেক member-এর pay / receive amount। Tap করে Paid / Unpaid mark + note (যেমন bKash)। |
| **My month card** *(Member)* | নিজের meals, rate, cost, market, bill share, I owe / I receive, paid status। |
| **Recent bazaar** | শেষ ৩টা bazaar entry; না থাকলে Bazaar tab-এ যাওয়ার CTA। |
| **Pull-to-refresh** | নিচে টেনে data refresh। |

---

## 5. Meals

প্রতিদিনের meal হিসাব।

| Feature | Description |
|---------|-------------|
| **Meal types** | Morning, Evening, Night, Rate, Guest। |
| **Quantity** | 0.5 step করে (যেমন 0.5, 1, 1.5)। |
| **Date picker** | Bangla date support; আজকের তারিখ highlight। |
| **Member filter** *(Admin)* | নির্দিষ্ট member-এর meal দেখা। |
| **Add meal** | Member → request (approve পর্যন্ত pending)। Admin → সরাসরি add। |
| **Bulk add** *(Admin)* | একসাথে অনেক member-এর meal; presets (1·1·1, half morning, morning only) + live total। |
| **Pending queue** | Admin approve / reject করে। Pending meal count-এ ধরা হয় না। |
| **Edit / delete** *(Admin)* | Approved meal edit বা delete। |
| **Month lock** | Closed month-এ meal add/edit বন্ধ। |

---

## 6. Bazaar — expenses (Market list)

কে কত টাকার বাজার করেছে।

| Feature | Description |
|---------|-------------|
| **Market list** | সব bazaar entry list। |
| **Filters** | This month / Last month / All, date filter, member filter (Admin)। |
| **Add market** | Multi-item form: item name, qty, amount, notes, shopper (Admin), due/বাকি flag। |
| **Due (বাকি)** | এখনো বাকি থাকা খরচ mark করা। |
| **Pending approve** | Member request → Admin approve / reject। |
| **Own entries** | Member সাধারণত নিজের approved entry দেখে। |
| **Edit / delete** *(Admin)* | Entry ঠিক করা বা মুছে ফেলা। |

---

## 7. Bazaar — schedule (duty dates)

কে কোন তারিখে বাজার করবে।

| Feature | Description |
|---------|-------------|
| **Set date** *(Admin)* | Member + date range দিয়ে duty schedule set। |
| **Request date** *(Member)* | নিজের জন্য duty date request। |
| **Run status** | Upcoming / Running / Completed। |
| **Pending requests** | Admin date request approve / reject করে। |
| **Bazaar swap** | দুই জন duty date বিনিময়। Member request পাঠায়; Admin approve করে বা সরাসরি swap / reassign করে। |

---

## 8. Report

Month-end আর daily হিসাব।

| Feature | Description |
|---------|-------------|
| **Mode banner** | Admin = সব member। Member = শুধু নিজের। |
| **Monthly settlement** | Meals × rate + bill share − deposits ± Eid bonus → কে কত দেবে / পাবে। |
| **Daily report** | নির্দিষ্ট দিনের meals by type, spend, meal rate, shoppers / my market। |
| **Smart meal chart** | Member × day grid (Breakfast / Lunch / Dinner style B/L/D)। |
| **Trends** | Last 6 months: meals, market, rate comparison। |
| **PDF export** | Monthly statement PDF। |
| **Excel export** | Meal chart Excel download। |

---

## 9. Mess bills

মাসিক fixed খরচ।

| Feature | Description |
|---------|-------------|
| **Bill types** | Cook, Rent, Electricity, Water, Utility, Eid bonus। |
| **Add / edit** *(Admin)* | Type, amount, note, month। Member শুধু দেখে। |
| **Month navigator** | অন্য month-এর bill দেখা। |
| **Total** | ওই month-এর সব bill যোগফল। |

---

## 10. Settings

| Feature | Description |
|---------|-------------|
| **Members list** | Avatar, name, role, room, “You” badge। |
| **Manage member** | Room edit, make/remove Admin (Super Admin), transfer Super Admin, mess থেকে remove। |
| **Add member** *(Super Admin)* | Email + password account তৈরি করে mess-এ add। |
| **Share code** | Mess code copy / invite share। |
| **Theme** | Forest, Ocean, Teal, Sunset, Indigo, Midnight + custom color + dark mode। |
| **Language** | Bangla / English পুরো app। |
| **Reminders** | Local notification on/off: meal (~5:30 PM), bazaar duty, settle-up। |
| **Month close / unlock** *(Admin)* | Month lock করলে edit বন্ধ; unlock করে আবার খোলা যায়। |
| **Notifications** | Inbox-এ যাওয়া। |
| **Analytics** | Trends screen। |
| **Privacy / Help / About** | Policy page, how-to dialog, about dialog। |
| **Social links** | YouTube / Facebook। |
| **Leave mess** | Mess ছেড়ে বের হওয়া (confirm)। |
| **Logout** | Sign out (confirm)। |

---

## 11. Notifications

| Feature | Description |
|---------|-------------|
| **Push notification** | Approval, bill, swap ইত্যাদি alert। |
| **Inbox** | In-app list; unread highlight, mark all read, swipe delete, delete all। |
| **Deep link** | Tap করলে সংশ্লিষ্ট screen-এ যায় (meal / bazaar / swap / bill)। |
| **Local reminders** | Meal, bazaar duty, settle-up সময় মনে করিয়ে দেয় (web-এ নয়)। |

---

## 12. Other system features

| Feature | Description |
|---------|-------------|
| **Month lock** | Closed month-এ meal / market / bill edit বন্ধ; দেখা যায়। |
| **Payment tracking** | Admin Paid / Unpaid mark করে; note রাখা যায় (bKash ইত্যাদি)। |
| **Offline support** | Firestore offline persistence — net না থাকলেও আগের data দেখা যায়। |
| **Crash reporting** | Firebase Crashlytics। |

---

## 13. All screens

### Entry
1. **Splash** — boot / brand loading  
2. **Onboarding** — first-time intro (4 pages)  
3. **Login** — Google / Email / Register entry  
4. **Email Login** — email + password + forgot password  
5. **Register** — new account  
6. **Mess Setup** — create or join mess  
7. **Privacy Policy** — privacy text  

### Main tabs (Home shell)
8. **Home** — dashboard  
9. **Meals** — daily meal log  
10. **Bazaar Hub** — List + Schedule segments  
11. **Market List** — bazaar expenses  
12. **Bazaar Schedule** — duty dates  
13. **Report Hub** — Monthly + Daily segments  
14. **Monthly Report** — settlement  
15. **Daily Report** — day-wise hisab  
16. **Settings** — Members + Settings segments  

### Push screens
17. **Add / Edit Market** — new or edit bazaar entry  
18. **Bazaar Swap** — duty date exchange  
19. **Mess Bills** — fixed monthly bills  
20. **Meal Chart** — B/L/D attendance grid  
21. **Analytics Trends** — 6-month charts  
22. **Notification Inbox** — in-app alerts  

### Community (built, currently OFF)
23. **Community Hub** — Feed / Friends / Chat tabs  
24. **Community Feed** — vacancy posts  
25. **Post Detail** — likes + comments  
26. **Create Vacancy Post** — new vacancy ad  
27. **Friends** — requests + friend list  
28. **Public Profile** — user profile  
29. **Chat Inbox** — conversation list  
30. **Chat Thread** — DM messages  

---

## 14. Community features *(flag OFF — Phase 2)*

| Feature | Description |
|---------|-------------|
| **Vacancy feed** | Seat খালি থাকলে post (seats, rent, location, optional mess code)। |
| **Likes / comments** | Post-এ react ও comment। |
| **Friends** | Friend request send / accept / reject। |
| **Public profile** | Bio, mess status, message button। |
| **Chat** | Friend-দের সাথে DM। |
