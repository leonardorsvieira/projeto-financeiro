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
// O módulo :app compila fora da pasta do projeto (C:\build\meubolso\app).
// Precisa ser definido aqui, antes dos plugins do Android serem aplicados:
// trocar o buildDir dentro de app/build.gradle.kts deixava o R8 do release
// procurando os arquivos de proguard na pasta antiga.
project(":app") {
    layout.buildDirectory.set(file("C:/build/meubolso/app"))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
