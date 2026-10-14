package com.routineplanner.app

import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodChannel
import ir.myket.billingclient.IabHelper
import ir.myket.billingclient.util.IabResult
import ir.myket.billingclient.util.Purchase

// پرداختِ مایکت (کتابخانه‌ی رسمی myket-billing-client) — فقط در فلیورِ «myket» کامپایل می‌شود.
// همان قراردادِ StoreBilling و همان شکلِ خروجی/کدهای خطای نسخه‌ی بازار، تا لایه‌ی Dart یکی بماند.
class StoreBillingImpl(private val activity: ComponentActivity) : StoreBilling {
    companion object {
        // کلید «عمومی» RSA پنل مایکت (بخش «پرداخت درون‌برنامه‌ای» ← کلید RSA). افشای آن خطری ندارد.
        private const val MYKET_RSA_KEY = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCNYKVozyadfP1pkRDcvvhZ1E5LSjuwhm40+ExlAEH2jT+HSYg00H4c0ghPglXBNMivgkp3Z8CwoFtoxD4xqCnctNwW5y+/AIdm0HReKK/MhVZJ3UcAd5JSf+Sh9jGZDQ1n54Hv8Oxm2Fv25gVEXKXN1tIh95mxHcyoVmablW08kQIDAQAB"
        private const val MYKET_PACKAGE = "ir.mservices.market"
    }

    override val storeId = "myket"
    private var helper: IabHelper? = null
    private var ready = false

    private fun myketInstalled(): Boolean = try {
        activity.packageManager.getPackageInfo(MYKET_PACKAGE, 0); true
    } catch (e: Exception) { false }

    override fun dispose() {
        try { helper?.dispose() } catch (_: Exception) {}
        helper = null; ready = false
    }

    override fun connect(result: MethodChannel.Result) {
        if (ready && helper != null) { result.success(mapOf("connected" to true)); return }
        val key = MYKET_RSA_KEY.trim()
        if (key.isEmpty()) { result.error("connection_failed", "کلید RSA مایکت تنظیم نشده است", null); return }
        if (!myketInstalled()) { result.error("connection_failed", "مایکت روی گوشی نصب نیست", null); return }
        try {
            dispose()
            val h = IabHelper(activity, key)
            helper = h
            h.startSetup { r ->
                if (r.isSuccess) { ready = true; result.success(mapOf("connected" to true)) }
                else result.error("connection_failed", r.message, null)
            }
        } catch (e: Exception) {
            result.error("connection_failed", e.message ?: "connection failed", null)
        }
    }

    private fun purchaseMap(p: Purchase) = mapOf(
        "productId" to p.sku,
        "purchaseToken" to p.token,
        "payload" to p.developerPayload,
        // زمانِ خرید از سرور مایکت — مبنای مطمئنِ انقضا (نه ساعت گوشی)
        "purchaseTime" to p.purchaseTime
    )

    override fun purchase(productId: String, result: MethodChannel.Result) {
        val h = helper
        if (h == null || !ready) { result.error("not_connected", "ابتدا باید connect صدا زده شود", null); return }
        var answered = false
        fun once(block: () -> Unit) { if (!answered) { answered = true; block() } }
        try {
            h.launchPurchaseFlow(activity, productId, IabHelper.OnIabPurchaseFinishedListener { r: IabResult, info: Purchase? ->
                when {
                    r.isSuccess && info != null -> once { result.success(purchaseMap(info)) }
                    r.response == IabHelper.BILLING_RESPONSE_RESULT_USER_CANCELED || r.response == IabHelper.IABHELPER_USER_CANCELLED ->
                        once { result.error("cancelled", "کاربر خرید را لغو کرد", null) }
                    r.response == IabHelper.BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED ->
                        // پلنی که قبلاً خریده و مصرف نشده: همان رسید را برمی‌گردانیم (بازیابی)
                        h.queryInventoryAsync(false) { qr, inv ->
                            val p = if (qr.isSuccess) inv?.getPurchase(productId) else null
                            once { if (p != null) result.success(purchaseMap(p)) else result.error("purchase_failed", r.message, null) }
                        }
                    r.response == IabHelper.BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE ->
                        once { result.error("connection_failed", r.message, null) }
                    r.response == IabHelper.BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE ->
                        once { result.error("purchase_failed", "item not found: " + r.message, null) }
                    else -> once { result.error("purchase_failed", r.message, null) }
                }
            })
        } catch (e: Exception) {
            once { result.error("failed_to_begin", e.message ?: "failed to begin purchase flow", null) }
        }
    }

    override fun consume(token: String, result: MethodChannel.Result) {
        val h = helper
        if (h == null || !ready) { result.error("not_connected", "ابتدا باید connect صدا زده شود", null); return }
        h.queryInventoryAsync(false) { qr, inv ->
            if (!qr.isSuccess) { result.error("consume_failed", qr.message, null); return@queryInventoryAsync }
            val p = inv?.allPurchases?.firstOrNull { it.token == token }
            if (p == null) { result.success(mapOf("consumed" to true)); return@queryInventoryAsync } // چیزی برای مصرف نیست
            h.consumeAsync(p) { _, cr ->
                if (cr.isSuccess) result.success(mapOf("consumed" to true)) else result.error("consume_failed", cr.message, null)
            }
        }
    }

    override fun getPurchased(result: MethodChannel.Result) {
        val h = helper
        if (h == null || !ready) { result.error("not_connected", "ابتدا باید connect صدا زده شود", null); return }
        h.queryInventoryAsync(false) { qr, inv ->
            if (!qr.isSuccess) { result.error("query_failed", qr.message, null); return@queryInventoryAsync }
            result.success(mapOf("products" to (inv?.allPurchases ?: emptyList()).map { purchaseMap(it) }))
        }
    }

    // صفحه‌ی ثبتِ نظرِ همین برنامه در مایکت؛ اگر نشد، صفحه‌ی وب
    override fun openReview(result: MethodChannel.Result) {
        val pkg = activity.packageName
        try {
            val i = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("myket://comment?id=$pkg"))
            i.setPackage(MYKET_PACKAGE)
            activity.startActivity(i)
            result.success(mapOf("opened" to true))
        } catch (e: Exception) {
            try {
                activity.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("https://myket.ir/app/$pkg")))
                result.success(mapOf("opened" to true))
            } catch (e2: Exception) {
                result.error("no_store", "مایکت باز نشد", null)
            }
        }
    }
}
