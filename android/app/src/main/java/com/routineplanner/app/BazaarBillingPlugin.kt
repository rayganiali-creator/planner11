package com.routineplanner.app

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.request.PurchaseRequest

// ============================================================
// پلاگین پرداخت درون‌برنامه‌ای کافه‌بازار (روی کتابخانه‌ی رسمی Poolakey)
// ------------------------------------------------------------
// چون تأیید نهایی خرید سمت سرور (Cloudflare Worker) انجام می‌شه، این‌جا
// SecurityCheck.Disable استفاده شده تا نیازی به کلید RSA محلی نباشه.
// ============================================================
@CapacitorPlugin(name = "BazaarBilling")
class BazaarBillingPlugin : Plugin() {

    private lateinit var payment: Payment
    private var connection: Connection? = null

    override fun load() {
        val paymentConfig = PaymentConfiguration(localSecurityCheck = SecurityCheck.Disable)
        payment = Payment(context = context, config = paymentConfig)
    }

    @PluginMethod
    fun connect(call: PluginCall) {
        connection = payment.connect {
            connectionSucceed {
                call.resolve(JSObject().put("connected", true))
            }
            connectionFailed { throwable ->
                call.reject("connection_failed", throwable.message ?: "connection failed")
            }
            disconnected {
                // اتصال قطع شد؛ در صورت نیاز دوباره connect صدا زده می‌شود
            }
        }
    }

    @PluginMethod
    fun purchase(call: PluginCall) {
        val productId = call.getString("productId")
        if (productId == null) {
            call.reject("productId الزامی است")
            return
        }
        if (connection?.getState() != ConnectionState.Connected) {
            call.reject("not_connected", "ابتدا باید connect صدا زده شود")
            return
        }

        payment.purchaseProduct(
            registry = activity.activityResultRegistry,
            request = PurchaseRequest(productId = productId)
        ) {
            purchaseFlowBegan {
                // فرآیند خرید (رفتن به صفحه‌ی پرداخت کافه‌بازار) شروع شد
            }
            failedToBeginFlow { throwable ->
                call.reject("failed_to_begin", throwable.message ?: "failed to begin purchase flow")
            }
            purchaseSucceed { purchaseInfo ->
                val ret = JSObject()
                ret.put("productId", purchaseInfo.productId)
                ret.put("purchaseToken", purchaseInfo.purchaseToken)
                ret.put("payload", purchaseInfo.payload)
                // زمان خرید از سرور کافه‌بازار — مبنای مطمئنِ محاسبه‌ی انقضا (نه ساعت گوشی)
                ret.put("purchaseTime", purchaseInfo.purchaseTime)
                call.resolve(ret)
            }
            purchaseCanceled {
                call.reject("cancelled", "کاربر خرید را لغو کرد")
            }
            purchaseFailed { throwable ->
                call.reject("purchase_failed", throwable.message ?: "purchase failed")
            }
        }
    }

    @PluginMethod
    fun consume(call: PluginCall) {
        val purchaseToken = call.getString("purchaseToken")
        if (purchaseToken == null) {
            call.reject("purchaseToken الزامی است")
            return
        }
        payment.consumeProduct(purchaseToken) {
            consumeSucceed {
                call.resolve(JSObject().put("consumed", true))
            }
            consumeFailed { throwable ->
                call.reject("consume_failed", throwable.message ?: "consume failed")
            }
        }
    }

    @PluginMethod
    fun getPurchasedProducts(call: PluginCall) {
        payment.getPurchasedProducts {
            querySucceed { purchasedProducts ->
                val arr = com.getcapacitor.JSArray()
                purchasedProducts.forEach { p ->
                    val o = JSObject()
                    o.put("productId", p.productId)
                    o.put("purchaseToken", p.purchaseToken)
                    o.put("purchaseTime", p.purchaseTime)
                    arr.put(o)
                }
                val ret = JSObject()
                ret.put("products", arr)
                call.resolve(ret)
            }
            queryFailed { throwable ->
                call.reject("query_failed", throwable.message ?: "query failed")
            }
        }
    }

    // ذخیره‌ی فایل در پوشه‌ی عمومی Download/RoutinePlanner از راه MediaStore (روش رسمی اندروید ۱۰+،
    // بدون نیاز به هیچ مجوزی). روی اندروید قدیمی‌تر reject می‌شه و JS به Documents / اشتراک‌گذاری برمی‌گرده.
    @PluginMethod
    fun saveToDownloads(call: PluginCall) {
        val fileName = call.getString("fileName") ?: return call.reject("fileName required")
        val mime = call.getString("mimeType") ?: "application/octet-stream"
        val data = call.getString("data") ?: return call.reject("data required")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q) return call.reject("legacy_android")
        try {
            val bytes = android.util.Base64.decode(data, android.util.Base64.DEFAULT)
            val values = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, mime)
                // مستقیم داخلِ خودِ پوشه‌ی Downloads (نه زیرپوشه) تا در فهرستِ دانلودها دیده شود
                put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS)
                put(android.provider.MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = context.contentResolver
            val uri = resolver.insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return call.reject("insert_failed")
            val out = resolver.openOutputStream(uri) ?: return call.reject("stream_failed")
            out.use { it.write(bytes); it.flush() }
            // پایانِ نوشتن: فایل از حالتِ «در حالِ نوشتن» خارج و برای همه‌ی برنامه‌ها قابل دیدن می‌شود
            val done = android.content.ContentValues().apply { put(android.provider.MediaStore.MediaColumns.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
            call.resolve(JSObject().put("uri", uri.toString()))
        } catch (e: Exception) {
            call.reject("save_failed", e.message)
        }
    }

    override fun handleOnDestroy() {
        connection?.disconnect()
        super.handleOnDestroy()
    }
}
