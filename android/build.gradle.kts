buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Updated AGP so compileSdk = 36 works
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ❗ Removed the broken JavaCompile block that caused all compilation errors

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
