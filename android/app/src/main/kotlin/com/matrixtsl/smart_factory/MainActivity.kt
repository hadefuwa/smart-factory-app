package com.matrixtsl.smart_factory

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.matrixtsl.smart_factory/plc"
    private lateinit var plcManager: PLCManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        plcManager = PLCManager()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    val ip = call.argument<String>("ip")
                    val rack = call.argument<Int>("rack") ?: 0
                    val slot = call.argument<Int>("slot") ?: 1

                    if (ip == null) {
                        result.error("INVALID_ARGUMENT", "IP address is required", null)
                    } else {
                        plcManager.connect(ip, rack, slot, result)
                    }
                }
                "disconnect" -> {
                    plcManager.disconnect()
                    result.success(true)
                }
                "getConnectionStatus" -> {
                    plcManager.getConnectionStatus(result)
                }
                "readDB" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val start = call.argument<Int>("start")
                    val size = call.argument<Int>("size")

                    if (dbNumber == null || start == null || size == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, start, and size are required", null)
                    } else {
                        plcManager.readDB(dbNumber, start, size, result)
                    }
                }
                "writeDB" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val start = call.argument<Int>("start")
                    val data = call.argument<List<Int>>("data")

                    if (dbNumber == null || start == null || data == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, start, and data are required", null)
                    } else {
                        val byteArray = data.map { it.toByte() }.toByteArray()
                        plcManager.writeDB(dbNumber, start, byteArray, result)
                    }
                }
                "readBool" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")
                    val bitOffset = call.argument<Int>("bitOffset")

                    if (dbNumber == null || byteOffset == null || bitOffset == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, byteOffset, and bitOffset are required", null)
                    } else {
                        plcManager.readBool(dbNumber, byteOffset, bitOffset, result)
                    }
                }
                "writeBool" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")
                    val bitOffset = call.argument<Int>("bitOffset")
                    val value = call.argument<Boolean>("value")

                    if (dbNumber == null || byteOffset == null || bitOffset == null || value == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, byteOffset, bitOffset, and value are required", null)
                    } else {
                        plcManager.writeBool(dbNumber, byteOffset, bitOffset, value, result)
                    }
                }
                "readInt" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")

                    if (dbNumber == null || byteOffset == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber and byteOffset are required", null)
                    } else {
                        plcManager.readInt(dbNumber, byteOffset, result)
                    }
                }
                "writeInt" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")
                    val value = call.argument<Int>("value")

                    if (dbNumber == null || byteOffset == null || value == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, byteOffset, and value are required", null)
                    } else {
                        plcManager.writeInt(dbNumber, byteOffset, value, result)
                    }
                }
                "readDInt" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")

                    if (dbNumber == null || byteOffset == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber and byteOffset are required", null)
                    } else {
                        plcManager.readDInt(dbNumber, byteOffset, result)
                    }
                }
                "writeDInt" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")
                    val value = call.argument<Int>("value")

                    if (dbNumber == null || byteOffset == null || value == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, byteOffset, and value are required", null)
                    } else {
                        plcManager.writeDInt(dbNumber, byteOffset, value, result)
                    }
                }
                "readReal" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")

                    if (dbNumber == null || byteOffset == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber and byteOffset are required", null)
                    } else {
                        plcManager.readReal(dbNumber, byteOffset, result)
                    }
                }
                "writeReal" -> {
                    val dbNumber = call.argument<Int>("dbNumber")
                    val byteOffset = call.argument<Int>("byteOffset")
                    val value = call.argument<Double>("value")

                    if (dbNumber == null || byteOffset == null || value == null) {
                        result.error("INVALID_ARGUMENT", "dbNumber, byteOffset, and value are required", null)
                    } else {
                        plcManager.writeReal(dbNumber, byteOffset, value, result)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        plcManager.dispose()
    }
}
