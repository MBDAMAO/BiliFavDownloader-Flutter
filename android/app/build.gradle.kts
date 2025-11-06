import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.damao.bili_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 使用 Java 11 特性并编译为 Java 11 字节码
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            // 生成适用于 Java 11 的 Kotlin 字节码
        }
    }

    defaultConfig {
        minSdk = 24 // Flutter 插件默认是 21（Android 5.0），你设置为 24 比较安全。
        targetSdk = flutter.targetSdkVersion // 始终设置为最新稳定版（Flutter 会自动跟进）
        versionCode = flutter.versionCode // versionCode：一个整数，用于 Google Play 判断是否是新版本（必须递增）。
        versionName = flutter.versionName // versionName：展示给用户看的版本号。
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // 可选启用混淆
            isShrinkResources = false // 可选启用资源压缩
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            isUniversalApk = true  // 不生成包含所有 ABI 的 APK
        }
    }
}

flutter {
    source = "../.."
}
