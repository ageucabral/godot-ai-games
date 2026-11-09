# Regras do R8 (encolhe e otimiza o código Java/Kotlin da versão da Play; recomendação da Play Console).
# O motor Godot chama o Java pelo nome (JNI e reflexão): essas classes ficam como estão.
-keep class org.godotengine.** { *; }
-keep class com.godot.game.** { *; }
# Nosso plugin (singleton NaLata): o Godot acha os métodos @UsedByGodot e os sinais pelo nome.
-keep class app.nalata.godot.** { *; }
-keepclassmembers class * {
    @org.godotengine.godot.plugin.UsedByGodot <methods>;
}
-dontwarn org.godotengine.**
# Linhas de erro legíveis no Play Console (com o arquivo mapping.txt enviado junto).
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses,EnclosingMethod
-renamesourcefileattribute SourceFile
