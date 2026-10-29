plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must be after android & kotlin
    id("com.google.gms.google-services")
}

// Google Maps key for AndroidManifest: taken from the Flutter --dart-define(-from-file)
// values, falling back to MAPS_API_KEY in android/local.properties.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotBlank() }
        ?.map { String(java.util.Base64.getDecoder().decode(it)) }
        ?.mapNotNull { entry ->
            val i = entry.indexOf('=')
            if (i > 0) entry.substring(0, i) to entry.substring(i + 1) else null
        }
        ?.toMap()
        ?: emptyMap()

val localProperties = java.util.Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

val googleMapsApiKey: String =
    dartDefines["GOOGLE_MAPS_API_KEY"]
        ?: localProperties.getProperty("MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.example.drugscript"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Fixed this line
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.drugscript"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    implementation("com.google.firebase:firebase-analytics")

    // ✅ Required for Java 8+ APIs like Local Notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
