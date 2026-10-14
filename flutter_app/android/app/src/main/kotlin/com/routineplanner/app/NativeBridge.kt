package com.routineplanner.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import androidx.activity.ComponentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// ============================================================
// پلِ Native برای Flutter (MethodChannel «rp/native»)
// پرداخت و ثبتِ نظر به فروشگاهِ همین بیلد (StoreBillingImpl در فلیورِ bazaar/myket) سپرده می‌شود.
// ============================================================
class NativeBridge(private val activity: ComponentActivity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "rp/native")
    private val billing: StoreBilling = StoreBillingImpl(activity)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        billing.dispose()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "storeId" -> result.success(billing.storeId)
            "connect" -> billing.connect(result)
            "purchase" -> {
                val productId = call.argument<String>("productId")
                if (productId == null) result.error("bad_args", "productId الزامی است", null) else billing.purchase(productId, result)
            }
            "consume" -> {
                val token = call.argument<String>("purchaseToken")
                if (token == null) result.error("bad_args", "purchaseToken الزامی است", null) else billing.consume(token, result)
            }
            "getPurchasedProducts" -> billing.getPurchased(result)
            "saveToDownloads" -> saveToDownloads(call, result)
            "openReview" -> billing.openReview(result)
            else -> result.notImplemented()
        }
    }

    // ذخیره در Downloads با MediaStore (اندروید ۱۰+، بدون مجوز). روی اندروید قدیمی‌تر legacy_android برمی‌گرداند.
    private fun saveToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val mime = call.argument<String>("mimeType") ?: "application/octet-stream"
        val data = call.argument<String>("data")
        if (fileName == null || data == null) { result.error("bad_args", "fileName/data required", null); return }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) { result.error("legacy_android", "legacy android", null); return }
        try {
            val bytes = Base64.decode(data, Base64.DEFAULT)
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = activity.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            if (uri == null) { result.error("insert_failed", "insert failed", null); return }
            val out = resolver.openOutputStream(uri)
            if (out == null) { result.error("stream_failed", "stream failed", null); return }
            out.use { it.write(bytes); it.flush() }
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
            result.success(mapOf("uri" to uri.toString()))
        } catch (e: Exception) {
            result.error("save_failed", e.message, null)
        }
    }
}
