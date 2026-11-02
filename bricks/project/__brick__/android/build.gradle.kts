allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
{{#hasBackendFirestore}}
subprojects {
    if (name == "cloud_firestore") {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                if (namespace == null) {
                    namespace = "io.flutter.plugins.firebase.firestore"
                }
            }
        }
    }
}
{{/hasBackendFirestore}}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
