@tool
extends EditorExportPlugin
## Põe o plugin Android (nalata-release.aar) e as bibliotecas do Google no APK/AAB.
## As versões precisam ser as mesmas de android/plugin/build.gradle.

const DEPENDENCIES := [
	"com.google.android.gms:play-services-ads:24.4.0",
	"androidx.credentials:credentials:1.3.0",
	"androidx.credentials:credentials-play-services-auth:1.3.0",
	"com.google.android.libraries.identity.googleid:googleid:1.1.1",
	"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1",
	"com.google.android.play:integrity:1.4.0",
	"com.android.installreferrer:installreferrer:2.2",
]


func _get_name() -> String:
	return "NaLata"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(["nalata_android/bin/nalata-release.aar"])


func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(DEPENDENCIES)
