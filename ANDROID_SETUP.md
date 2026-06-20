# android/app/build.gradle  — replace the defaultConfig block with this
# (minimum required changes for media_kit + hive_flutter)
#
# KEY CHANGES vs default Flutter template:
#   • minSdkVersion → 21   (media_kit requirement)
#   • compileSdkVersion → 34
#   • Add multiDexEnabled true (large dependency count)

# ─────────────────────────────────────────────────────────────────────────────
# Paste this into android/app/build.gradle inside android { defaultConfig { … } }
# ─────────────────────────────────────────────────────────────────────────────
#
#   defaultConfig {
#       applicationId "com.yourcompany.clipfeed"
#       minSdkVersion 21            # ← media_kit minimum
#       targetSdkVersion 34
#       versionCode flutterVersionCode.toInteger()
#       versionName flutterVersionName
#       multiDexEnabled true        # ← add this
#   }
#
# Also set compileSdkVersion 34 at the top of android { … }
#
# In android/build.gradle make sure kotlin version is >= 1.9.0:
#   ext.kotlin_version = '1.9.22'

# ── android/app/src/main/AndroidManifest.xml additions ───────────────────────
# Add inside <manifest …>:
#   <uses-permission android:name="android.permission.INTERNET" />
#
# Already present in default Flutter template — verify it's not commented out.
