
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        // Add other dependencies you might have, for example:
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
