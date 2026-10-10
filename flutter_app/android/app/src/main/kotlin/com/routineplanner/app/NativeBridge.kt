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
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.request.PurchaseRequest

// ============================================================
// پلِ Native برای Flutter (MethodChannel «rp/native»)
// ------------------------------------------------------------
// همان قراردادِ BazaarBillingPlugin نسخه‌ی Capacitor: connect / purchase / consume /
// getPurchasedProducts / saveToDownloads. خطاها با همان کدها برمی‌گردند
// (cancelled, connection_failed, not_connected, failed_to_begin, purchase_failed, ...)
// تا پیام‌های کاربر یکی بماند.
// راستی‌آزمایی امضای خرید روی دستگاه با کلید عمومی RSA کافه‌بازار انجام می‌شود (برنامه سرور ندارد).
// ============================================================
class NativeBridge(private val activity: ComponentActivity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    companion object {
        // کلید «عمومی» RSA پنل کافه‌بازار (همان نسخه‌ی Capacitor). افشای آن خطری ندارد.
        private const val BAZAAR_RSA_KEY = "MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwCPqJVjr5X6oT/7td1K8ighUDXlJ0DW5a33kxudgx4hNSFWAb3rw7Ss05XNevcCP3LkzL8zMsJV1+bPeFlrV2XamXOfgy/d3ooe2tkuM49CTZvhCvsStGiLudQEQ+NUODX2sCJYwH5QU3PYpRfFiDXqoJ+clIGu8c7tMpSng7hKhv43gvbRQOC+6fX3Eu9VmCUWzX0zDQmS+EqnLdaJOApb/oBm9oCAdMPDWss6lKMCAwEAAQ=="
    }

    private val channel = MethodChannel(messenger, "rp/native")
    private val payment: Payment
    private var connection: Connection? = null

    init {
        val key = BAZAAR_RSA_KEY.trim()
        val securityCheck = if (key.isEmpty()) SecurityCheck.Disable else SecurityCheck.Enable(rsaPublicKey = key)
        payment = Payment(context = activity, config = PaymentConfiguration(localSecurityCheck = securityCheck))
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        connection?.disconnect()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(result)
            "purchase" -> purchase(call, result)
            "consume" -> consume(call, result)
            "getPurchasedProducts" -> getPurchased(result)
            "saveToDownloads" -> saveToDownloads(call, result)
            "openReview" -> openReview(result)
            else -> result.notImplemented()
        }
    }

    // صفحه‌ی ثبتِ نظرِ همین برنامه در کافه‌بازار (بدونِ مجوزِ اضافه)؛ اگر بازار نبود، صفحه‌ی وب
    private fun openReview(result: MethodChannel.Result) {
        val pkg = activity.packageName
        try {
            val i = android.content.Intent(android.content.Intent.ACTION_EDIT, android.net.Uri.parse("bazaar://details?id=$pkg"))
            i.setPackage("com.farsitel.bazaar")
            activity.startActivity(i)
            result.success(mapOf("opened" to true))
        } catch (e: Exception) {
            try {
                activity.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("https://cafebazaar.ir/app/$pkg")))
                result.success(mapOf("opened" to true))
            } catch (e2: Exception) {
                result.error("no_bazaar", "کافه‌بازار باز نشد", null)
            }
        }
    }

    private fun connect(result: MethodChannel.Result) {
        var answered = false
        fun once(block: () -> Unit) { if (!answered) { answered = true; block() } }
        connection = payment.connect {
            connectionSucceed { once { result.success(mapOf("connected" to true)) } }
            connectionFailed { t -> once { result.error("connection_failed", t.message ?: "connection failed", null) } }
            disconnected { }
        }
    }

    private fun purchase(call: MethodCall, result: MethodChannel.Result) {
        val productId = call.argument<String>("productId")
        if (productId == null) { result.error("bad_args", "productId الزامی است", null); return }
        if (connection?.getState() != ConnectionState.Connected) { result.error("not_connected", "ابتدا باید connect صدا زده شود", null); return }
        var answered = false
        fun once(block: () -> Unit) { if (!answered) { answered = true; block() } }
        payment.purchaseProduct(registry = activity.activityResultRegistry, request = PurchaseRequest(productId = productId)) {
            purchaseFlowBegan { }
            failedToBeginFlow { t -> once { result.error("failed_to_begin", t.message ?: "failed to begin purchase flow", null) } }
            purchaseSucceed { p ->
                once {
                    result.success(mapOf(
                        "productId" to p.productId,
                        "purchaseToken" to p.purchaseToken,
                        "payload" to p.payload,
                        // زمان خرید از سرور کافه‌بازار — مبنای مطمئنِ انقضا (نه ساعت گوشی)
                        "purchaseTime" to p.purchaseTime
                    ))
                }
            }
            purchaseCanceled { once { result.error("cancelled", "کاربر خرید را لغو کرد", null) } }
            purchaseFailed { t -> once { result.error("purchase_failed", t.message ?: "purchase failed", null) } }
        }
    }

    private fun consume(call: MethodCall, result: MethodChannel.Result) {
        val token = call.argument<String>("purchaseToken")
        if (token == null) { result.error("bad_args", "purchaseToken الزامی است", null); return }
        payment.consumeProduct(token) {
            consumeSucceed { result.success(mapOf("consumed" to true)) }
            consumeFailed { t -> result.error("consume_failed", t.message ?: "consume failed", null) }
        }
    }

    private fun getPurchased(result: MethodChannel.Result) {
        payment.getPurchasedProducts {
            querySucceed { list ->
                result.success(mapOf("products" to list.map { p ->
                    mapOf("productId" to p.productId, "purchaseToken" to p.purchaseToken, "purchaseTime" to p.purchaseTime)
                }))
            }
            queryFailed { t -> result.error("query_failed", t.message ?: "query failed", null) }
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
