# WorkManager creates this Room database implementation through reflection
# during AndroidX Startup. Preserve its no-argument constructor in release APKs.
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
