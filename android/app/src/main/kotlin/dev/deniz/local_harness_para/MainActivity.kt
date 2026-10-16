package dev.deniz.local_harness_para

import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FLAG_SECURE toggle for Money pages (spec §11.6).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "local_harness_para/secure_window")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Huawei watch quick entry (Wear Engine) — see WatchBridge.
        val watchChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "local_harness_para/watch")
        val watch = WatchBridge(this, watchChannel)
        watchChannel.setMethodCallHandler { call, result ->
            if (call.method == "start") watch.start(result) else result.notImplemented()
        }
        val debuggable =
            applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (debuggable) watch.registerDebugInjector()

        // Local Harness hub contract §3 (same channel in every app).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "local_harness/hub")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publishSnapshot" -> {
                        val json = call.arguments as? String
                        if (json == null) {
                            result.error("bad_args", "publishSnapshot expects a JSON string", null)
                        } else {
                            try {
                                writeSnapshot(json)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("io", "snapshot write failed", null)
                            }
                        }
                    }
                    "readPeerSnapshot" -> {
                        val app = call.arguments as? String
                        result.success(app?.let { readPeerSnapshot(it) })
                    }
                    "isInstalled" -> {
                        val app = call.arguments as? String
                        result.success(app != null && isInstalled(packageFor(app)))
                    }
                    "launchApp" -> {
                        val app = call.argument<String>("app")
                        val route = call.argument<String>("route")
                        result.success(app != null && launchApp(packageFor(app), route))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Atomic write: tmp file + rename, so the provider never serves half a file. */
    private fun writeSnapshot(json: String) {
        val target = File(filesDir, HubProvider.SNAPSHOT_FILE)
        val tmp = File(filesDir, HubProvider.SNAPSHOT_FILE + ".tmp")
        tmp.writeText(json)
        if (!tmp.renameTo(target)) {
            target.delete()
            if (!tmp.renameTo(target)) throw java.io.IOException("rename failed")
        }
    }

    private fun packageFor(app: String) = "dev.deniz.local_harness_$app"

    private fun readPeerSnapshot(app: String): String? = try {
        contentResolver.call(
            Uri.parse("content://${packageFor(app)}.hub"),
            "snapshot",
            null,
            null
        )?.getString("json")
    } catch (e: Exception) {
        null // Not installed, no permission, or provider crashed.
    }

    private fun isInstalled(pkg: String): Boolean =
        packageManager.getLaunchIntentForPackage(pkg) != null

    private fun launchApp(pkg: String, route: String?): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(pkg) ?: return false
        if (route != null) intent.putExtra("lh_route", route)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
