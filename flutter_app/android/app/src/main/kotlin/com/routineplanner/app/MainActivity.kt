package com.routineplanner.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity (یک ComponentActivity است): Poolakey برای باز کردنِ صفحه‌ی پرداخت به
// activityResultRegistry نیاز دارد.
class MainActivity : FlutterFragmentActivity() {
    private var bridge: NativeBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = NativeBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        bridge?.dispose()
        super.onDestroy()
    }
}
