package com.tumype.camrun

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // El canal de los push (`avisos`, el mismo id que manda el backend).
        // Importancia alta = sale como banner y suena; con el canal generico
        // de FCM solo aparece el icono en la barra. Crearlo otra vez no hace
        // nada: Android conserva lo que el usuario haya cambiado.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                "avisos",
                getString(R.string.push_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
        }
    }
}
