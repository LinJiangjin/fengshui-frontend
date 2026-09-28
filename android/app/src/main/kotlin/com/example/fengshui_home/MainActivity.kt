package com.example.fengshui_home

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /// 与 Flutter AppColors.bg 一致的宣纸底色 #F5F1E8
    private val APP_BG_COLOR = 0xFFF5F1E8.toInt()

    /// 真正的 edge-to-edge：内容延伸到状态栏 / 手势条后面，
    /// 配合透明系统栏，状态栏区域直接露出 App 米色背景。
    /// Dart 侧不要调用 SystemChrome（PlatformPlugin 会重置这些标志）。
    private fun applyEdgeToEdge() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.setSystemBarsAppearance(
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS,
            )
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            )
        }
        if (Build.VERSION.SDK_INT < 35) {
            // 部分国产 ROM（如 MIUI）不允许窗口延伸到状态栏后面，
            // 透明状态栏会露出黑色垫底；改为直接刷成 App 底色，视觉等同透明。
            // （API 35 起系统强制 edge-to-edge，此设置失效，无需再设）
            @Suppress("DEPRECATION")
            window.statusBarColor = APP_BG_COLOR
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.TRANSPARENT
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyEdgeToEdge()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applyEdgeToEdge()
    }
}
