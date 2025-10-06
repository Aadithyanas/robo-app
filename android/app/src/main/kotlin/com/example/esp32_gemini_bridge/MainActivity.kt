package com.example.esp32_gemini_bridge

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "bluetooth_serial"
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothSocket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scanForDevices" -> {
                    scanForDevices(result)
                }
                "connectToDevice" -> {
                    val address = call.argument<String>("address")
                    val name = call.argument<String>("name")
                    connectToDevice(address, name, result)
                }
                "sendMessage" -> {
                    val message = call.argument<String>("message")
                    sendMessage(message, result)
                }
                "readMessage" -> {
                    readMessage(result)
                }
                "disconnect" -> {
                    disconnect(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scanForDevices(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_ERROR", "Bluetooth not supported", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_ERROR", "Bluetooth not enabled", null)
            return
        }

        val devices = mutableListOf<Map<String, String>>()
        val pairedDevices = bluetoothAdapter!!.bondedDevices
        
        for (device in pairedDevices) {
            val deviceInfo = mapOf(
                "name" to (device.name ?: "Unknown"),
                "address" to device.address
            )
            devices.add(deviceInfo)
        }

        result.success(devices)
    }

    private fun connectToDevice(address: String?, name: String?, result: MethodChannel.Result) {
        if (address == null) {
            result.error("CONNECTION_ERROR", "Device address is null", null)
            return
        }

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(address)
            val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // SPP UUID
            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
            
            bluetoothAdapter!!.cancelDiscovery()
            bluetoothSocket!!.connect()
            
            inputStream = bluetoothSocket!!.inputStream
            outputStream = bluetoothSocket!!.outputStream
            
            result.success(true)
        } catch (e: Exception) {
            result.error("CONNECTION_ERROR", "Failed to connect: ${e.message}", null)
        }
    }

    private fun sendMessage(message: String?, result: MethodChannel.Result) {
        if (outputStream == null) {
            result.error("SEND_ERROR", "Not connected", null)
            return
        }

        try {
            outputStream!!.write(message!!.toByteArray())
            result.success(true)
        } catch (e: Exception) {
            result.error("SEND_ERROR", "Failed to send: ${e.message}", null)
        }
    }

    private fun readMessage(result: MethodChannel.Result) {
        if (inputStream == null) {
            result.success(null)
            return
        }

        try {
            val buffer = ByteArray(1024)
            val bytes = inputStream!!.read(buffer)
            if (bytes > 0) {
                val message = String(buffer, 0, bytes)
                result.success(message)
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        try {
            inputStream?.close()
            outputStream?.close()
            bluetoothSocket?.close()
            inputStream = null
            outputStream = null
            bluetoothSocket = null
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCONNECT_ERROR", "Failed to disconnect: ${e.message}", null)
        }
    }
}
