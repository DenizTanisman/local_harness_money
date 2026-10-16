package dev.deniz.local_harness_para

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.Permission
import com.huawei.wearengine.p2p.Receiver
import io.flutter.plugin.common.MethodChannel

/**
 * Huawei watch quick entry (Wear Engine P2P). The watch app (watch/) sends a
 * small JSON per entry; it is forwarded to Dart as `entry` on the
 * `local_harness_para/watch` channel. Every failure is swallowed: without
 * Huawei Health or an approved Wear Engine permission Para works as before.
 */
class WatchBridge(private val activity: Activity, private val channel: MethodChannel) {
    companion object {
        /** Bundle name of the watch app (watch/entry/src/main/config.json). */
        const val WATCH_BUNDLE = "dev.deniz.para.watch"

        /**
         * Signing-certificate fingerprint of the watch app, from AppGallery
         * Connect after the watch app is created there (no colons).
         */
        const val WATCH_FINGERPRINT = "SET_WATCH_APP_FINGERPRINT"
    }

    private val receiver = Receiver { message ->
        val json = message?.data?.let { String(it, Charsets.UTF_8) } ?: return@Receiver
        activity.runOnUiThread { channel.invokeMethod("entry", json) }
    }

    /**
     * Debug builds only: lets `adb shell am broadcast -a
     * dev.deniz.local_harness_para.WATCH_TEST --es json '<entry>'` play the
     * watch's part, to test the phone side without a watch.
     */
    fun registerDebugInjector() {
        val injector = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                intent.getStringExtra("json")?.let { channel.invokeMethod("entry", it) }
            }
        }
        val filter = IntentFilter("dev.deniz.local_harness_para.WATCH_TEST")
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(injector, filter, Context.RECEIVER_EXPORTED)
        } else {
            activity.registerReceiver(injector, filter)
        }
    }

    fun start(result: MethodChannel.Result) {
        try {
            HiWear.getAuthClient(activity).requestPermission(object : AuthCallback {
                override fun onOk(permissions: Array<Permission>?) = connect(result)
                override fun onCancel() = result.success("auth_cancelled")
            }, Permission.DEVICE_MANAGER)
                .addOnFailureListener { result.success("auth_failed: ${it.message}") }
        } catch (e: Throwable) {
            result.success("unavailable: ${e.message}")
        }
    }

    private fun connect(result: MethodChannel.Result) {
        HiWear.getDeviceClient(activity).bondedDevices
            .addOnSuccessListener { devices ->
                val device = devices?.firstOrNull { it.isConnected }
                if (device == null) {
                    result.success("no_watch")
                    return@addOnSuccessListener
                }
                HiWear.getP2pClient(activity)
                    .setPeerPkgName(WATCH_BUNDLE)
                    .setPeerFingerPrint(WATCH_FINGERPRINT)
                    .registerReceiver(device, receiver)
                    .addOnSuccessListener { result.success("listening: ${device.name}") }
                    .addOnFailureListener { result.success("receiver_failed: ${it.message}") }
            }
            .addOnFailureListener { result.success("devices_failed: ${it.message}") }
    }
}
