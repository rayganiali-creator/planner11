package com.routineplanner.app

import io.flutter.plugin.common.MethodChannel

// قراردادِ پرداخت/نظر برای هر فروشگاه (bazaar | myket). پیاده‌سازی در پوشه‌ی فلیور است.
// خطاها با همان کدهای قبلی برمی‌گردند: cancelled, connection_failed, not_connected, failed_to_begin, purchase_failed, ...
interface StoreBilling {
    val storeId: String
    fun connect(result: MethodChannel.Result)
    fun purchase(productId: String, result: MethodChannel.Result)
    fun consume(token: String, result: MethodChannel.Result)
    fun getPurchased(result: MethodChannel.Result)
    fun openReview(result: MethodChannel.Result)
    fun dispose()
}
