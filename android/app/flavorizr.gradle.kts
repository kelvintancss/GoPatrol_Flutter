import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("staging") {
            dimension = "flavor-type"
            applicationId = "com.css.patrol.int"
            resValue(type = "string", name = "app_name", value = "Patrol Staging")
        }
        create("demo") {
            dimension = "flavor-type"
            applicationId = "com.css.patrol.demo"
            resValue(type = "string", name = "app_name", value = "Patrol Demo")
        }
        create("production") {
            dimension = "flavor-type"
            applicationId = "com.css.patrol"
            resValue(type = "string", name = "app_name", value = "Patrol")
        }
    }

    buildFeatures.resValues = true
}