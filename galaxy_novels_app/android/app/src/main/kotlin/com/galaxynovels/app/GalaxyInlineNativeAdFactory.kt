package com.galaxynovels.app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

class GalaxyInlineNativeAdFactory(
    private val context: Context,
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val placement = customOptions?.get("placement")?.toString().orEmpty()
        val background = colorOption(customOptions, "backgroundColor", Color.TRANSPARENT)
        val headlineColor = colorOption(customOptions, "headlineColor", Color.WHITE)
        val bodyColor = colorOption(customOptions, "bodyColor", 0xFFB0B7C3.toInt())
        val accentColor = colorOption(customOptions, "accentColor", 0xFF8EA9D1.toInt())
        val accentContentColor = colorOption(customOptions, "accentContentColor", Color.BLACK)

        val adView = NativeAdView(context).apply {
            setBackgroundColor(background)
            layoutDirection = View.LAYOUT_DIRECTION_RTL
        }
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutDirection = View.LAYOUT_DIRECTION_RTL
            setPadding(dp(placementPadding(placement)), dp(8), dp(placementPadding(placement)), dp(8))
        }
        adView.addView(
            row,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )

        val iconSize = if (placement == "novelDetails") 68 else 60
        val icon = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            contentDescription = null
            clipToOutline = true
            this.background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(12).toFloat()
                setColor(Color.TRANSPARENT)
            }
        }
        row.addView(icon, LinearLayout.LayoutParams(dp(iconSize), dp(iconSize)))

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), 0, dp(10), 0)
        }
        row.addView(
            content,
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f),
        )

        val attribution = TextView(context).apply {
            text = "إعلان"
            textSize = 10f
            setTextColor(bodyColor)
            maxLines = 1
        }
        content.addView(attribution)

        val headline = TextView(context).apply {
            textSize = 14f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(headlineColor)
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        content.addView(headline)

        val body = TextView(context).apply {
            textSize = 12f
            setTextColor(bodyColor)
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        content.addView(body)

        val advertiser = TextView(context).apply {
            textSize = 10f
            setTextColor(bodyColor)
            maxLines = 1
        }
        content.addView(advertiser)

        val callToAction = TextView(context).apply {
            gravity = Gravity.CENTER
            textSize = 12f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(accentContentColor)
            minWidth = dp(70)
            minHeight = dp(40)
            setPadding(dp(12), dp(8), dp(12), dp(8))
            this.background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(12).toFloat()
                setColor(accentColor)
            }
        }
        row.addView(callToAction)

        val adChoices = AdChoicesView(context)
        adView.addView(
            adChoices,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.TOP or Gravity.END,
            ),
        )

        adView.iconView = icon
        adView.headlineView = headline
        adView.bodyView = body
        adView.advertiserView = advertiser
        adView.callToActionView = callToAction
        adView.adChoicesView = adChoices

        headline.text = nativeAd.headline
        nativeAd.icon?.drawable?.let {
            icon.setImageDrawable(it)
            icon.visibility = View.VISIBLE
        } ?: run {
            icon.visibility = View.GONE
        }
        nativeAd.body?.let {
            body.text = it
            body.visibility = View.VISIBLE
        } ?: run {
            body.visibility = View.GONE
        }
        nativeAd.advertiser?.let {
            advertiser.text = it
            advertiser.visibility = View.VISIBLE
        } ?: run {
            advertiser.visibility = View.GONE
        }
        nativeAd.callToAction?.let {
            callToAction.text = it
            callToAction.visibility = View.VISIBLE
        } ?: run {
            callToAction.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun placementPadding(placement: String): Int = when (placement) {
        "rankings" -> 4
        "readerJourney" -> 4
        else -> 0
    }

    private fun colorOption(
        options: Map<String, Any>?,
        key: String,
        fallback: Int,
    ): Int = (options?.get(key) as? Number)?.toInt() ?: fallback

    private fun dp(value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
