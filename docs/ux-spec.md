# UX Specification — Warm Navy

**Status:** Task 0 proposal — awaiting approval  
**Design authority:** Root `DESIGN.md`  
**Product authority:** Root `PRODUCT.md`  
**Viewport baseline:** 390px wide mobile wireframes. Desktop notes describe responsive behavior, not a separate product.  
**Language/direction:** Arabic, RTL.  
**Counting rule:** Tap counts include explicit pointer/touch activations only. They exclude typing, scrolling, OS keyboard actions, waiting and confirmation dialogs unless the dialog itself requires an additional confirmation tap. “Before” is an estimate from the current route and widget structure, not a usability-study measurement. “After” is the proposed target.

## Shared shell and interaction model

- Mobile has five persistent destinations: الرئيسية، الحضور، التلاميذ، المتابعة، المزيد. Attendance is one tap away from every authenticated screen.
- More opens the complete navigation list, filtered using the existing role visibility rules. No new permissions are introduced.
- Desktop keeps the persistent right-side navigation; compact density is used for data tables.
- Offline indicator remains visible without obscuring the current task. Attendance writes continue to use the existing offline-first behavior.
- Existing route paths, role filtering and widget/test keys remain unchanged.

---

## 1. Login — تسجيل الدخول

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│                         [الوضع الليلي]│
│                                      │
│             [أيقونة الكنيسة]         │
│          أسرة تلاميذ المسيح           │
│        خدمة 5 و6 ابتدائي بنين         │
│      كنيسة السيدة العذراء بعياد بك   │
│                                      │
│  البريد الإلكتروني                   │
│  ┌────────────────────────────────┐  │
│  │  name@example.com              │  │
│  └────────────────────────────────┘  │
│                                      │
│  كلمة المرور                         │
│  ┌────────────────────────────────┐  │
│  │  •••••••••••••             [◉] │  │
│  └────────────────────────────────┘  │
│                                      │
│  [ ] تذكر البريد الإلكتروني          │
│                                      │
│  ┌────────────────────────────────┐  │
│  │          تسجيل الدخول          │  │
│  └────────────────────────────────┘  │
│                                      │
│  رسالة الخطأ / تأكيد البريد تظهر هنا │
└──────────────────────────────────────┘
```

### Desktop note
Centered, bounded login panel (max width approximately 460px) on the warm canvas. Keep the form at a comfortable reading width; do not stretch fields across a desktop viewport. The same hierarchy and fields apply in both themes.

### Single primary action
**تسجيل الدخول** — one full-width primary button. Theme toggle and remember-email checkbox are secondary controls.

### States
- **Loading:** button retains its width, disables duplicate submission and shows an inline progress indicator with label `جارٍ تسجيل الدخول...`.
- **Empty:** the login form is not an empty-data screen; required-field validation appears beside the relevant field.
- **Error:** inline form-level message with warning/error icon and concise Arabic copy; field validation remains field-specific. Email-not-confirmed feedback keeps the resend-confirmation action secondary.
- **Offline:** show a clear connection message and retain entered email/password state. Do not imply that an unauthenticated user can sign in offline; preserve the existing authentication/session semantics.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 1 | 1 | Submit credentials after fields are entered |

No tap reduction is claimed here; the improvement is clearer hierarchy, readable form controls and explicit feedback.

---

## 2. Dashboard — لوحة الخدمة

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│ لوحة الخدمة                 [مزامنة] │
├──────────────────────────────────────┤
│ خدمة تلاميذ المسيح                   │
│ كنيسة السيدة العذراء بعياد بك        │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │          تسجيل الحضور            │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ملخص الخدمة                          │
│ ┌────────────────┐ ┌───────────────┐ │
│ │ إجمالي التلاميذ│ │    معتمدون    │ │
│ │       120      │ │      108      │ │
│ └────────────────┘ └───────────────┘ │
│ ┌────────────────┐ ┌───────────────┐ │
│ │ بانتظار الاعتماد│ │   [مؤشر آخر]  │ │
│ │       12       │ │       —       │ │
│ └────────────────┘ └───────────────┘ │
│                                      │
│ إجراءات / ملخصات حسب الدور           │
│ ...                                  │
├──────────────────────────────────────┤
│ الرئيسية  الحضور  التلاميذ  المتابعة  المزيد │
└──────────────────────────────────────┘
```

*Metric values are illustrative placeholders, not real service data.*

### Desktop note
Use a two- or three-column metric grid according to available width. The attendance CTA stays visually first. Keep service identity and summary in one restrained surface; do not add nested cards or decorative charts. Preserve role-scoped metrics and existing dashboard content.

### Single primary action
**تسجيل الحضور** — direct route to the existing attendance flow.

### States
- **Loading:** render dashboard skeletons for service identity, CTA and metric cards. If cached values exist, show them immediately rather than replacing them with a blocking spinner.
- **Empty:** if no local service record exists, explain that service data is unavailable and provide a retry/connection action. If the service exists but has no students, show a concise empty roster summary and role-authorized next step.
- **Error:** service/dashboard error message with retry. Keep cached summary visible if available and label it as local/cached.
- **Offline:** show cached service and student metrics, plus a compact `غير متصل` / `بيانات محفوظة` status. The attendance CTA remains enabled when the local attendance workflow is available.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 1 | 1 | Open attendance using the dashboard CTA |

The dashboard already exposes a direct attendance action; this redesign preserves it and makes attendance directly reachable from the shell as well.

---

## 3. Attendance session — تسجيل حضور الفصل

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│ [رجوع] تسجيل الحضور       [مزامنة]   │
├──────────────────────────────────────┤
│ اجتماع الخدمة • التاريخ              │
│ الفصل: 5/6 ابتدائي                   │
│ ┌──────────────────────────────────┐ │
│ │ حاضر 18   غائب —   إجمالي 24     │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [بحث عن تلميذ..................][⌕]  │
│ [الكل] [حاضر] [غير مسجل]             │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ محمد ...                 [✓ حاضر]│ │
│ │                                  │ │
│ ├──────────────────────────────────┤ │
│ │ مينا ...               [تسجيل ✓] │ │
│ ├──────────────────────────────────┤ │
│ │ بيشوي ...             [تسجيل ✓] │ │
│ ├──────────────────────────────────┤ │
│ │ ...                              │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [مسح QR]                 [مراجعة]    │
├──────────────────────────────────────┤
│ الرئيسية  التلاميذ  الحضور  المزيد   │
└──────────────────────────────────────┘
```

### Desktop note
Use compact roster rows/table with name, class (in all-students mode), attendance state, check-in time and sync state. Keep search and status filters above the roster. QR scanning and review remain secondary actions. Avoid horizontal overflow; allow a table-to-list adaptation at tablet widths.

### Single primary action
**تسجيل حضور التلميذ** — one large, clearly labeled row action. A successful local check-in updates the row immediately and shows the existing attendance confirmation; it must not wait for network sync.

### States
- **Loading:** skeleton roster rows and summary placeholders. When the local roster is already available, render it while remote refresh continues.
- **Empty:** show `لا يوجد تلاميذ في هذا الفصل` with the permitted next step (e.g. add/register student where current role and flow allow it). In all-students mode, explain how to add/assign a student without inventing a new operation.
- **Error:** keep cached roster usable; show a non-blocking refresh error and retry. If no local roster exists, show an error panel with retry.
- **Offline:** persistent offline/pending-sync status. Local check-in remains available under the existing offline-first repository behavior; distinguish `تم التسجيل محليًا` from `تمت المزامنة`. Do not disable check-in solely because internet is unavailable.
- **Read-only meeting:** show a clear `عرض فقط` state and disable check-in/registration controls when the existing meeting rules mark the meeting read-only.
- **Already present:** show `حاضر` with check icon and do not offer a duplicate check-in action.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 5 | 4 | From another authenticated screen: open navigation, choose attendance, choose meeting, choose class, check in one student → proposed bottom-nav attendance, choose meeting, choose class, check in |

**Within the attendance session:** one tap to check in a listed student before and after. The redesign does not add confirmation steps to the repeated door check-in task.

---

## 4. Students list — سجل التلاميذ

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│ التلاميذ                  [إضافة +]  │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ ابحث بالاسم أو الهاتف...     [⌕] │ │
│ └──────────────────────────────────┘ │
│ [الكل] [معتمد] [بانتظار الاعتماد]    │
│                                      │
│ إجمالي 120       معتمد 108           │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ [صورة]  اسم التلميذ              │ │
│ │         الفصل • الصف             │ │
│ │         [✓ معتمد]                 │ │
│ ├──────────────────────────────────┤ │
│ │ [صورة]  اسم التلميذ              │ │
│ │         الفصل • الصف             │ │
│ │         [⌛ بانتظار الاعتماد]     │ │
│ ├──────────────────────────────────┤ │
│ │ [صورة]  اسم التلميذ              │ │
│ │         الفصل • الصف             │ │
│ │         [✓ معتمد]                 │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ الرئيسية  الحضور  التلاميذ  المتابعة  المزيد │
└──────────────────────────────────────┘
```

### Desktop note
Retain search, approval filters and metrics, but present the roster as a compact table when width permits. Keep name and status visible without horizontal scrolling. Stage/class exploration remains available to roles that currently see it; class-scoped roles continue to see their assigned scope only.

### Single primary action
**فتح ملف التلميذ** — activate the row. Add/import actions remain secondary and permission-controlled.

### States
- **Loading:** skeleton search/filter controls and roster rows. Show local rows immediately if cached.
- **Empty:** distinguish a genuinely empty roster from an empty search result. For a new roster, explain that students will appear after registration and show the add action only where allowed. For no search matches, offer clear-search.
- **Error:** if local data exists, retain it and show refresh failure with retry; if no data exists, show an error panel and retry.
- **Offline:** render the local roster and filters. Show that displayed records are locally saved; do not block search or opening a cached student profile.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 3 | 2 | From another authenticated screen: open navigation, choose students, open a student → proposed bottom-nav students, open a student |

Search typing and filter selection are not included in the count.

---

## 5. Student details — ملف التلميذ

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│ [رجوع] اسم التلميذ       [تعديل ⋮]  │
├──────────────────────────────────────┤
│ [صورة]  اسم التلميذ                  │
│         [✓ معتمد]                    │
│         المرحلة • الفصل              │
│                                      │
│ [الملف]       [الحضور]      [المتابعة]│
│                                      │
│ بيانات أساسية                        │
│ ┌──────────────────────────────────┐ │
│ │ تاريخ الميلاد                    │ │
│ │ الصف الدراسي                     │ │
│ │ المدرسة                          │ │
│ │ الهاتف                           │ │
│ └──────────────────────────────────┘ │
│                                      │
│ بيانات إضافية / ملاحظات              │
│ ...                                  │
│                                      │
│ [اعتماد التلميذ] (للمخولين فقط)      │
└──────────────────────────────────────┘
```

### Desktop note
Use a bounded profile header and a two-column details layout where space permits. Keep the three existing tabs (الملف، الحضور، المتابعة) as the information architecture. Edit, class assignment, archive and approval controls remain visible only under the current permission rules; do not move destructive actions into the primary action position.

### Single primary action
**تعديل البيانات** for users allowed to edit; **اعتماد التلميذ** for an authorized reviewer viewing a pending student. These are mutually contextual primary actions; do not show both as competing primary buttons. Other roles receive a read-only profile.

### States
- **Loading:** show profile header and tab skeletons while details load. Sensitive/secondary data can load independently without blocking the cached basic profile.
- **Empty:** if optional profile fields are missing, show `غير مسجل` rather than blank space. If attendance or follow-up has no entries, show a tab-specific empty state and the relevant permitted action.
- **Error:** show the basic cached profile when available; provide retry for failed detail/history sections. Mutation failures appear inline or as an actionable message and must not discard unsaved form values.
- **Offline:** display cached profile and history available locally. Existing edits/approval/archive behavior must retain current repository semantics and clearly say when a change is saved locally pending sync. Do not claim that remote synchronization completed.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 3 | 3 | Open a student from the list, open edit, save changes |

The task remains three explicit activations; the redesign improves control hierarchy and prevents destructive actions from competing with edit/approval.

---

## 6. App shell navigation — التنقل

### 390px mobile wireframe

```text
┌──────────────────────────────────────┐
│ اسم الصفحة                  [مزامنة] │
├──────────────────────────────────────┤
│                                      │
│             محتوى الصفحة             │
│                                      │
│                                      │
├──────────────────────────────────────┤
│ الرئيسية   الحضور   التلاميذ  المتابعة  المزيد │
│    ⌂        ✓        ♙        ✆       ⋯     │
└──────────────────────────────────────┘

عند فتح «المزيد»:
┌──────────────────────────────────────┐
│ الخدمة                               │
│  تحضيري                              │
│  النوتة الروحية                      │
│ الإدارة                              │
│  التقارير                            │
│  الخدام                              │
│  تصدير البيانات                      │
│  التخرج                              │
│  إعدادات الخدمة                      │
│ الحساب                               │
│  حسابي                               │
│  اختيار خدمة أخرى / تغيير الخدمة     │
│  تسجيل الخروج                        │
└──────────────────────────────────────┘
```

### Desktop note
Persistent right-side navigation at >=1100px, preserving the current complete navigation set and role-based filtering. Use an opaque surface, 1px divider and selected primary-container state. The top app bar contains current page title, sync status, theme control and account actions. At widths below 1100px, use the mobile shell; do not compress the full desktop sidebar into unreadable labels.

### Single primary action
**Navigate to Attendance** — fixed bottom-nav destination on mobile. All other destinations remain one tap away through their primary slot or the More list.

### States
- **Loading:** shell frame and current-page title render immediately; only profile/account details use compact placeholders.
- **Empty:** navigation itself has no empty state. If no service is selected, preserve the existing session/service selection flow rather than showing an empty navigation shell.
- **Error:** a failed profile lookup must not silently expand permissions. Show account/profile failure separately; retain only navigation entries authorized by the resolved identity.
- **Offline:** shell remains available; sync status explains pending or conflict state. Do not cover the current page with a full-screen offline modal.

### Main-task tap count
| Before | After target | Task |
|---:|---:|---|
| 2 | 1 | Navigate to a primary destination from a mobile page: open menu then choose item → tap its persistent bottom-nav item |
| 2 | 2 | Navigate to a secondary destination: open menu then choose item → open More then choose item |

The desktop sidebar remains one activation for every visible destination.

---

## 7. Acceptance checklist for Task 0

- [ ] Root `DESIGN.md` is the only token authority for both themes.
- [ ] All seven statuses use color + icon + Arabic label, with contrast ratios documented.
- [ ] Warm gold is limited to meaningful semantic highlights; it is not used as generic decoration.
- [ ] All six requested screens have 390px wireframes, desktop notes, one primary action, four operational states and tap-count comparisons.
- [ ] Attendance can be reached in one tap from every authenticated mobile screen.
- [ ] Existing route paths, business logic, data behavior, role visibility and widget/test keys remain unchanged.
- [ ] The legacy MASTER file no longer contradicts the root design system.
- [ ] No Dart files are changed in Task 0.
