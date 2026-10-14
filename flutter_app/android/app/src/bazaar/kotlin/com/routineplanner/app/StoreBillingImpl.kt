package com.routineplanner.app

import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.request.PurchaseRequest

// پرداختِ کافه‌بازار (Poolakey) — فقط در فلیورِ «bazaar» کامپایل می‌شود.
// راستی‌آزمایی امضای خرید روی دستگاه با کلید عمومی RSA کافه‌بازار انجام می‌شود (برنامه سرور ندارد).
class StoreBillingImpl(private val activity: ComponentActivity) : StoreBilling {
    companion object {
        // کلید «عمومی» RSA پنل کافه‌بازار. افشای آن خطری ندارد.
        private const val BAZAAR_RSA_KEY = "MIHNMA0GCSqGSIb3DQEBAQUAA4G7ADCBtwKBrwCPqJVjr5X6oT/7td1K8ighUDXlJ0DW5a33kxudgx4hNSFWAb3rw7Ss05XNevcCP3LkzL8zMsJV1+bPeFlrV2XamXOfgy/d3ooe2tkuM49CTZvhCvsStGiLudQEQ+NUODX2sCJYwH5QU3PYpRfFiDXqoJ+clIGu8c7tMpSng7hKhv43gvbRQOC+6fX3Eu9VmCUWzX0zDQmS+EqnLdaJOApb/oBm9oCAdMPDWss6lKMCAwEAAQ=="
    }

    override val storeId = "bazaar"
    private val payment: Payment
    private var connection: Connection? = null

    init {
        val key = BAZAAR_RSA_KEY.trim()
        val securityCheck = if (key.isEmpty()) SecurityCheck.Disable else SecurityCheck.Enable(rsaPublicKey = key)
        payment = Payment(context = activity, config = PaymentConfiguration(localSecurityCheck = securityCheck))
    }

    override fun dispose() { connection?.disconnect() }

    // صفحه‌ی ثبتِ نظرِ همین برنامه در کافه‌بازار؛ اگر بازار نبود، صفحه‌ی وب
    override fun openReview(result: MethodChannel.Result) {
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
                result.error("no_store", "کافه‌بازار باز نشد", null)
            }
        }
    }

    override fun connect(result: MethodChannel.Result) {
        var answered = false
        fun once(block: () -> Unit) { if (!answered) { answered = true; block() } }
        connection = payment.connect {
            connectionSucceed { once { result.success(mapOf("connected" to true)) } }
            connectionFailed { t -> once { result.error("connection_failed", t.message ?: "connection failed", null) } }
            disconnected { }
        }
    }

    override fun purchase(productId: String, result: MethodChannel.Result) {
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

    override fun consume(token: String, result: MethodChannel.Result) {
        payment.consumeProduct(token) {
            consumeSucceed { result.success(mapOf("consumed" to true)) }
            consumeFailed { t -> result.error("consume_failed", t.message ?: "consume failed", null) }
        }
    }

    override fun getPurchased(result: MethodChannel.Result) {
        payment.getPurchasedProducts {
            querySucceed { list ->
                result.success(mapOf("products" to list.map { p ->
                    mapOf("productId" to p.productId, "purchaseToken" to p.purchaseToken, "purchaseTime" to p.purchaseTime)
                }))
            }
            queryFailed { t -> result.error("query_failed", t.message ?: "query failed", null) }
        }
    }
}
