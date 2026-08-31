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
subprojects {
    project.evaluationDependsOn(":app")
}

// ---------------------------------------------------------------------------
// Surcharge du compileSdk des plugins.
//
// `flutter_secure_storage` 11.0.0 déclare en dur `compileSdk = 37` dans son
// android/build.gradle. Or Google ne publie AUCUN paquet `platforms;android-37` :
// la ligne API 37 n'existe qu'en versions mineures (37.0, 37.1, 37.2). Le build
// échoue donc sur « Failed to find target with hash string 'android-37' ».
//
// C'est un défaut du paquet, pas du projet. On aligne tous les sous-projets
// Android sur une plateforme réellement installée plutôt que de rétrograder la
// dépendance — cela protège aussi des autres plugins qui feraient la même chose.
//
// À retirer quand les plugins concernés auront corrigé leur déclaration.
// Vérification : `sdkmanager --list | grep "platforms;android-3"`.
// ---------------------------------------------------------------------------
val pluginCompileSdk = 36

subprojects {
    if (project.name == "app") return@subprojects
    project.afterEvaluate {
        val androidExt = project.extensions.findByName("android") ?: return@afterEvaluate
        val applied = androidExt.javaClass.methods
            .filter { it.parameterTypes.size == 1 }
            .firstOrNull { m ->
                (m.name == "setCompileSdk" &&
                    (m.parameterTypes[0] == Int::class.javaPrimitiveType ||
                        m.parameterTypes[0] == Integer::class.java)) ||
                    (m.name == "setCompileSdkVersion" &&
                        m.parameterTypes[0] == Int::class.javaPrimitiveType)
            }
            ?.runCatching { invoke(androidExt, pluginCompileSdk) }
            ?.isSuccess ?: false
        if (applied) {
            logger.lifecycle("compileSdk de ${project.name} aligné sur $pluginCompileSdk")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
