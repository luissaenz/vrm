# 02-Interfaz-Reactiva (mm2.5)

## §0 VERIF
| # | el | st | ev |
|---|---|---|---|
|1|setFocus|✅|cam134|
|2|setFlash|✅|cam122|
|3|setExpos|✅|cam144|
|4|_focus|✅|rec67|
|5|_street|✅|rec62|
|6|_ghost|✅|rec63|
|7|prefs|✅|pub45|
|8|infl_save|❌|no save|
|9|correct_path|❌|appDir|
|10|theme|❌|hard|

## 1️⃣ DATA
→ /vrm_data/{id}
→ miss:prefs_schema
→ NEW:theme,telep,infl,device svc

## 2️⃣ CODE
|fn|fl|st|
|---|---|---|
|setFocus|cam|✅|
|loadTheme|theme|CREAR|
|saveTheme|theme|CREAR|
|loadTelep|tel|CREAR|
|saveTelep|tel|CREAR|
|loadInfl|inf|CREAR|
|saveInfl|inf|CREAR|
|clrVRM|stor|CREAR|
|getDevId|dev|CREAR|

dep:device_info_plus

## 3️⃣ BACKEND
→ local→camera+SharedPrefs

## 4️⃣ FULL+DX
UI→St→Svc→prefs
gap:toggle↛svc,tel≠persist

TOOL:PrefsInspector

## 5️⃣ ACCEPT
```
✅ pref keys
✅ focus↔toggle
✅ theme→persist
✅ infl→JSON
✅ tel→persist
✅ clr→/vrm
✅ devId=real
```

## 6️⃣ RISK
path A/i: MED

## 7️⃣ PLAN
|0|PrefInsp|scr/pref|0.5|
|1|Theme|svc|1|
|2|Telep|svc|1|
|3|Infl|svc|1|
|4|Dev|svc|0.5|
|5|Clr|svc|1|
|6|focus|rec|1|
|7|theme|set|0.5|
|8|infl|inf|1|
|9|tel|tel|0.5|
|10|test|test|1|
TOT:8.5h