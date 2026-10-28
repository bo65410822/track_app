import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取 key.properties（不提交 git）。不存在时 keystoreProperties 为空，release 退回 debug 签名。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 高德 Key：有 key.properties 时按 release/debug 分别取。
// debug Key 已公开（仅用于调试），作为缺省值保证无 key.properties 时也能调试；
// release Key 必须在 key.properties 配置，不进 git。
val defaultDebugAmapKey = "78c2f888a255e66a2c9b1344d48486bb"
val amapKeyDebug = keystoreProperties.getProperty("amapKeyDebug") ?: defaultDebugAmapKey
val amapKeyRelease = keystoreProperties.getProperty("amapKeyRelease") ?: amapKeyDebug

android {
    namespace = "com.zhanbo.track"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.zhanbo.track"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["AMAP_API_KEY"] = amapKeyDebug
        }
        release {
            // 有 key.properties 用正式签名，否则退回 debug 签名，保证无密钥环境也能构建
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            manifestPlaceholders["AMAP_API_KEY"] = amapKeyRelease
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
