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

    override fun handleOnDestroy() {
        connection?.disconnect()
        super.handleOnDestroy()
    }
}
