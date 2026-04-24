package com.example.flutter_frontend

import android.nfc.NfcAdapter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NFC_DISPATCH_CHANNEL =
            "com.example.flutter_frontend/nfc_dispatch"
    }

    private var isNfcDispatchBlocked = false
    private val emptyReaderCallback = NfcAdapter.ReaderCallback { }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NFC_DISPATCH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlocked" -> {
                    isNfcDispatchBlocked = call.argument<Boolean>("blocked") ?: false
                    applyNfcReaderMode()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        applyNfcReaderMode()
    }

    override fun onPause() {
        disableNfcReaderMode()
        super.onPause()
    }

    private fun applyNfcReaderMode() {
        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return

        if (!isNfcDispatchBlocked) {
            adapter.disableReaderMode(this)
            return
        }

        val flags =
            NfcAdapter.FLAG_READER_NFC_A or
                NfcAdapter.FLAG_READER_NFC_B or
                NfcAdapter.FLAG_READER_NFC_F or
                NfcAdapter.FLAG_READER_NFC_V or
                NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK

        adapter.enableReaderMode(this, emptyReaderCallback, flags, null)
    }

    private fun disableNfcReaderMode() {
        NfcAdapter.getDefaultAdapter(this)?.disableReaderMode(this)
    }
}
