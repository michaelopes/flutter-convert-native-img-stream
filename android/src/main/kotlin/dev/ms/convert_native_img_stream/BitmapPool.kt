package dev.ms.convert_native_img_stream

import android.graphics.Bitmap

object BitmapPool {
    private const val MAX_SIZE_BYTES = 10 * 1024 * 1024 // 10MB

    private val pool = LinkedHashMap<String, MutableList<Bitmap>>(0, 0.75f, true) // LRU ordering
    private var currentSize = 0

    private fun getKey(width: Int, height: Int, config: Bitmap.Config): String {
        return "$width-$height-${config.name}"
    }

    @Synchronized
    fun get(width: Int, height: Int, config: Bitmap.Config = Bitmap.Config.ARGB_8888): Bitmap {
        val key = getKey(width, height, config)
        val list = pool[key]
        if (list != null && list.isNotEmpty()) {
            val bmp = list.removeLast()
            currentSize -= bmp.byteCount
            if (list.isEmpty()) pool.remove(key)
            if (!bmp.isRecycled) return bmp
        }
        return Bitmap.createBitmap(width, height, config)
    }

    @Synchronized
    fun put(bitmap: Bitmap) {
        if (bitmap.isRecycled) return

        val key = getKey(bitmap.width, bitmap.height, bitmap.config)
        val size = bitmap.byteCount

        if (size > MAX_SIZE_BYTES) {
            bitmap.recycle()
            return
        }

        pool.getOrPut(key) { mutableListOf() }.add(bitmap)
        currentSize += size

        // Remove old bitmaps if exceeding max size
        trimToSize()
    }

    private fun trimToSize() {
        val it = pool.entries.iterator()
        while (currentSize > MAX_SIZE_BYTES && it.hasNext()) {
            val entry = it.next()
            val bitmaps = entry.value
            while (bitmaps.isNotEmpty() && currentSize > MAX_SIZE_BYTES) {
                val bmp = bitmaps.removeFirst()
                currentSize -= bmp.byteCount
                bmp.recycle()
            }
            if (bitmaps.isEmpty()) it.remove()
        }
    }

    @Synchronized
    fun clear() {
        pool.values.flatten().forEach { it.recycle() }
        pool.clear()
        currentSize = 0
    }
}
