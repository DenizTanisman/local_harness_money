package dev.deniz.local_harness_para

import android.content.ContentProvider
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import java.io.File

/**
 * Hub contract §2: exposes this app's last published snapshot
 * (filesDir/hub_snapshot.json, written by MainActivity's publishSnapshot)
 * to the Local Harness hub. Read-only, call()-based; the table API is unused.
 */
class HubProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val ctx = context ?: return null
        // android:permission does not guard call() on every API level.
        if (ctx.checkCallingPermission(HUB_PERMISSION) != PackageManager.PERMISSION_GRANTED) {
            throw SecurityException("Caller lacks $HUB_PERMISSION")
        }
        return when (method) {
            "ping" -> Bundle().apply {
                putString("app", APP)
                putInt("schema", SCHEMA)
            }
            "snapshot" -> Bundle().apply {
                val file = File(ctx.filesDir, SNAPSHOT_FILE)
                if (file.exists()) putString("json", file.readText())
            }
            else -> null
        }
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int = 0

    companion object {
        const val HUB_PERMISSION = "dev.deniz.local_harness.permission.HUB"
        const val APP = "para"
        const val SCHEMA = 1
        const val SNAPSHOT_FILE = "hub_snapshot.json"
    }
}
