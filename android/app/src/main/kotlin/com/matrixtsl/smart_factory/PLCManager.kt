package com.matrixtsl.smart_factory

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.sourceforge.snap7.moka7.S7
import com.sourceforge.snap7.moka7.S7Client
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * PLCManager handles communication with Siemens S7 PLCs using Moka7 library
 * This is a pure Java implementation - no native libraries required!
 */
class PLCManager {
    private val tag = "PLCManager"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var client: S7Client? = null
    private var isConnected = false
    private var currentIp: String? = null
    private var currentRack: Int = 0
    private var currentSlot: Int = 0

    /**
     * Connect to a PLC
     * @param ip PLC IP address (e.g., "192.168.1.100")
     * @param rack Rack number (typically 0)
     * @param slot Slot number (typically 1 for S7-1200/1500, 2 for S7-300/400)
     * @param result Callback with connection result
     */
    fun connect(ip: String, rack: Int, slot: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (isConnected) {
                    disconnect()
                }

                Log.d(tag, "Connecting to PLC at $ip (Rack: $rack, Slot: $slot)")

                client = S7Client()
                val connectResult = client!!.ConnectTo(ip, rack, slot)

                if (connectResult == 0) {
                    isConnected = true
                    currentIp = ip
                    currentRack = rack
                    currentSlot = slot

                    Log.i(tag, "Successfully connected to PLC at $ip")
                    mainHandler.post {
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Connected to PLC at $ip"
                        ))
                    }
                } else {
                    val errorText = S7Client.ErrorText(connectResult)
                    Log.e(tag, "Failed to connect: $errorText (Code: $connectResult)")
                    mainHandler.post {
                        result.error(
                            "CONNECTION_FAILED",
                            "Failed to connect to PLC: $errorText",
                            connectResult
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Connection error: ${e.message}", e)
                mainHandler.post {
                    result.error("CONNECTION_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Disconnect from PLC
     */
    fun disconnect() {
        try {
            client?.Disconnect()
            isConnected = false
            currentIp = null
            Log.d(tag, "Disconnected from PLC")
        } catch (e: Exception) {
            Log.e(tag, "Error disconnecting: ${e.message}", e)
        }
    }

    /**
     * Check if connected to PLC
     */
    fun getConnectionStatus(result: MethodChannel.Result) {
        mainHandler.post {
            result.success(mapOf(
                "connected" to isConnected,
                "ip" to currentIp,
                "rack" to currentRack,
                "slot" to currentSlot
            ))
        }
    }

    /**
     * Read a data block from PLC
     * @param dbNumber Data block number
     * @param start Starting byte
     * @param size Number of bytes to read
     */
    fun readDB(dbNumber: Int, start: Int, size: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(size)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, start, size, buffer)

                if (readResult == 0) {
                    mainHandler.post {
                        result.success(buffer.toList()) // Convert to List<Int> for Flutter
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    Log.e(tag, "Read DB error: $errorText (Code: $readResult)")
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Read DB exception: ${e.message}", e)
                mainHandler.post {
                    result.error("READ_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Write to a data block in PLC
     * @param dbNumber Data block number
     * @param start Starting byte
     * @param data Byte array to write
     */
    fun writeDB(dbNumber: Int, start: Int, data: ByteArray, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val writeResult = client!!.WriteArea(S7.S7AreaDB, dbNumber, start, data.size, data)

                if (writeResult == 0) {
                    mainHandler.post {
                        result.success(true)
                    }
                } else {
                    val errorText = S7Client.ErrorText(writeResult)
                    Log.e(tag, "Write DB error: $errorText (Code: $writeResult)")
                    mainHandler.post {
                        result.error("WRITE_FAILED", errorText, writeResult)
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Write DB exception: ${e.message}", e)
                mainHandler.post {
                    result.error("WRITE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Read a boolean from PLC (bit)
     * @param dbNumber Data block number
     * @param byteOffset Byte offset
     * @param bitOffset Bit offset (0-7)
     */
    fun readBool(dbNumber: Int, byteOffset: Int, bitOffset: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(1)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, byteOffset, 1, buffer)

                if (readResult == 0) {
                    val value = S7.GetBitAt(buffer, 0, bitOffset)
                    mainHandler.post {
                        result.success(value)
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Read bool exception: ${e.message}", e)
                mainHandler.post {
                    result.error("READ_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Write a boolean to PLC (bit)
     */
    fun writeBool(dbNumber: Int, byteOffset: Int, bitOffset: Int, value: Boolean, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                // Read current byte
                val buffer = ByteArray(1)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, byteOffset, 1, buffer)

                if (readResult == 0) {
                    // Modify bit
                    S7.SetBitAt(buffer, 0, bitOffset, value)

                    // Write back
                    val writeResult = client!!.WriteArea(S7.S7AreaDB, dbNumber, byteOffset, 1, buffer)

                    if (writeResult == 0) {
                        mainHandler.post {
                            result.success(true)
                        }
                    } else {
                        val errorText = S7Client.ErrorText(writeResult)
                        mainHandler.post {
                            result.error("WRITE_FAILED", errorText, writeResult)
                        }
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Write bool exception: ${e.message}", e)
                mainHandler.post {
                    result.error("WRITE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Read an integer (INT - 2 bytes) from PLC
     */
    fun readInt(dbNumber: Int, byteOffset: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(2)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, byteOffset, 2, buffer)

                if (readResult == 0) {
                    val value = S7.GetShortAt(buffer, 0)
                    mainHandler.post {
                        result.success(value.toInt())
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("READ_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Write an integer (INT - 2 bytes) to PLC
     */
    fun writeInt(dbNumber: Int, byteOffset: Int, value: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(2)
                S7.SetWordAt(buffer, 0, value)

                val writeResult = client!!.WriteArea(S7.S7AreaDB, dbNumber, byteOffset, 2, buffer)

                if (writeResult == 0) {
                    mainHandler.post {
                        result.success(true)
                    }
                } else {
                    val errorText = S7Client.ErrorText(writeResult)
                    mainHandler.post {
                        result.error("WRITE_FAILED", errorText, writeResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("WRITE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Read a double integer (DINT - 4 bytes) from PLC
     */
    fun readDInt(dbNumber: Int, byteOffset: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(4)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, byteOffset, 4, buffer)

                if (readResult == 0) {
                    val value = S7.GetDIntAt(buffer, 0)
                    mainHandler.post {
                        result.success(value)
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("READ_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Write a double integer (DINT - 4 bytes) to PLC
     */
    fun writeDInt(dbNumber: Int, byteOffset: Int, value: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(4)
                S7.SetDIntAt(buffer, 0, value)

                val writeResult = client!!.WriteArea(S7.S7AreaDB, dbNumber, byteOffset, 4, buffer)

                if (writeResult == 0) {
                    mainHandler.post {
                        result.success(true)
                    }
                } else {
                    val errorText = S7Client.ErrorText(writeResult)
                    mainHandler.post {
                        result.error("WRITE_FAILED", errorText, writeResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("WRITE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Read a float (REAL - 4 bytes) from PLC
     */
    fun readReal(dbNumber: Int, byteOffset: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(4)
                val readResult = client!!.ReadArea(S7.S7AreaDB, dbNumber, byteOffset, 4, buffer)

                if (readResult == 0) {
                    val value = S7.GetFloatAt(buffer, 0)
                    mainHandler.post {
                        result.success(value.toDouble())
                    }
                } else {
                    val errorText = S7Client.ErrorText(readResult)
                    mainHandler.post {
                        result.error("READ_FAILED", errorText, readResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("READ_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Write a float (REAL - 4 bytes) to PLC
     */
    fun writeReal(dbNumber: Int, byteOffset: Int, value: Double, result: MethodChannel.Result) {
        executor.execute {
            try {
                if (!isConnected || client == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Not connected to PLC", null)
                    }
                    return@execute
                }

                val buffer = ByteArray(4)
                S7.SetFloatAt(buffer, 0, value.toFloat())

                val writeResult = client!!.WriteArea(S7.S7AreaDB, dbNumber, byteOffset, 4, buffer)

                if (writeResult == 0) {
                    mainHandler.post {
                        result.success(true)
                    }
                } else {
                    val errorText = S7Client.ErrorText(writeResult)
                    mainHandler.post {
                        result.error("WRITE_FAILED", errorText, writeResult)
                    }
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("WRITE_ERROR", e.message ?: "Unknown error", null)
                }
            }
        }
    }

    /**
     * Cleanup resources
     */
    fun dispose() {
        disconnect()
        executor.shutdown()
    }
}
