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

subprojects {
    if (project.name != "app") {
        val configureSdk: () -> Unit = {
            val android = project.extensions.findByName("android")
            if (android != null) {
                var applied = false
                for (name in listOf("setCompileSdk", "compileSdkVersion")) {
                    for (method in android.javaClass.methods) {
                        if (method.name == name && method.parameterCount == 1) {
                            val paramType = method.parameterTypes[0]
                            try {
                                if (paramType == Integer::class.java || paramType == Int::class.javaPrimitiveType) {
                                    method.invoke(android, 36)
                                    applied = true
                                    break
                                } else if (paramType == String::class.java) {
                                    method.invoke(android, "android-36")
                                    applied = true
                                    break
                                }
                            } catch (_: Exception) {}
                        }
                    }
                    if (applied) break
                }
            }
        }

        val configureTasks: () -> Unit = {
            tasks.matching { it.name.contains("AarMetadata") }.configureEach {
                enabled = true
                try {
                    val method = this.javaClass.getMethod("getCompileSdkVersion")
                    val prop = method.invoke(this)
                    if (prop is org.gradle.api.provider.Property<*>) {
                        @Suppress("UNCHECKED_CAST")
                        (prop as org.gradle.api.provider.Property<String>).set("android-36")
                    }
                } catch (_: Exception) {}
            }
        }

        if (state.executed) {
            configureSdk()
            configureTasks()
        } else {
            afterEvaluate {
                configureSdk()
                configureTasks()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
