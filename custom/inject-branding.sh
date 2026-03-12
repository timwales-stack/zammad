#!/bin/bash
# Black Raven Service Desk — Branding Injection Script
# Runs at container startup before Zammad boots

# 1. Inject custom CSS into layout templates
DESKTOP_LAYOUT="/opt/zammad/app/views/layouts/desktop.html.erb"
LEGACY_LAYOUT="/opt/zammad/app/views/layouts/application.html.erb"
CSS_LINK='<link rel="stylesheet" href="/assets/blackraven-theme.css" />'
for layout in "$DESKTOP_LAYOUT" "$LEGACY_LAYOUT"; do
  if [ -f "$layout" ] && ! grep -q "blackraven-theme" "$layout"; then
    sed -i "s|</head>|${CSS_LINK}\n</head>|" "$layout"
    echo "Injected Black Raven CSS into $(basename $layout)"
  fi
done

# 2. Replace logo symbols in SVG sprite (legacy UI icons)
SPRITE="/opt/zammad/public/assets/images/icons.svg"
if [ -f "$SPRITE" ] && ! grep -q "Black Raven" "$SPRITE"; then
  # Replace icon-logo (Zammad bird -> Black Raven icon)
  ruby -e '
    content = File.read("'"$SPRITE"'")

    # Black Raven icon paths (white fills, viewBox 0 0 386 362 scaled to 42x36)
    raven_logo = %q(<symbol id="icon-logo" viewBox="0 0 386 362"><title>Black Raven</title><path d="M 231,170 L 211,226 L 177,316 L 176,321 L 176,324 L 181,326 L 183,328 L 229,353 L 231,353 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 55,148 L 126,222 L 143,241 L 161,259 L 161,260 L 180,280 L 182,276 L 183,271 L 188,260 L 226,156 L 228,148 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 39,53 L 12,78 L 39,78 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 49,47 L 49,138 L 104,138 L 128,114 L 128,113 L 131,110 L 121,100 L 121,99 L 110,88 L 100,76 L 73,47 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 371,39 L 367,37 L 359,35 L 354,36 L 318,71 L 322,68 L 327,66 L 369,41 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 231,18 L 168,86 L 124,131 L 124,132 L 118,138 L 231,138 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 241,131 L 362,15 L 350,15 L 349,14 L 319,14 L 288,12 L 241,11 Z" fill="currentColor" fill-rule="evenodd"/></symbol>)

    # Replace icon-logo
    content.sub!(/<symbol id="icon-logo".*?<\/symbol>/m, raven_logo)

    # Replace icon-logotype with "BLACK RAVEN" wordmark
    raven_logotype = %q(<symbol id="icon-logotype" viewBox="0 0 674 112"><title>Black Raven</title><path d="M 539,81 L 539,86 L 540,88 L 587,89 L 588,87 L 587,78 L 585,77 L 542,77 L 540,78 L 540,80 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 96,80 L 96,87 L 98,89 L 120,89 L 122,87 L 122,80 L 121,78 L 119,77 L 97,78 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 600,69 L 601,89 L 611,88 L 611,68 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 253,67 L 241,68 L 240,71 L 235,76 L 227,79 L 227,89 L 231,90 L 232,89 L 235,89 L 243,85 L 251,76 L 254,69 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 539,54 L 539,60 L 540,62 L 583,63 L 584,61 L 584,53 L 583,51 L 540,52 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 600,26 L 600,29 L 622,60 L 631,71 L 639,82 L 641,86 L 644,89 L 655,88 L 654,25 L 644,26 L 643,67 L 639,63 L 622,40 L 620,36 L 611,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 539,28 L 539,34 L 540,36 L 542,37 L 586,37 L 588,35 L 588,27 L 587,25 L 540,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 472,25 L 470,27 L 470,29 L 482,59 L 485,64 L 494,88 L 497,90 L 505,90 L 507,88 L 530,32 L 531,29 L 530,25 L 520,25 L 518,27 L 514,39 L 502,69 L 499,69 L 499,67 L 489,42 L 488,37 L 502,37 L 504,36 L 505,34 L 505,28 L 504,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 430,26 L 412,68 L 413,72 L 423,72 L 425,70 L 432,51 L 435,46 L 438,44 L 438,46 L 448,70 L 450,77 L 410,77 L 408,78 L 405,84 L 406,89 L 468,88 L 467,82 L 450,44 L 448,37 L 443,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 346,26 L 347,36 L 349,37 L 380,37 L 384,39 L 387,44 L 387,49 L 382,54 L 379,55 L 346,56 L 346,88 L 348,89 L 357,88 L 358,86 L 359,66 L 373,66 L 376,69 L 382,80 L 388,89 L 400,88 L 400,85 L 389,69 L 387,65 L 396,57 L 398,53 L 399,49 L 399,42 L 396,34 L 390,28 L 382,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 314,25 L 303,25 L 301,26 L 265,60 L 264,62 L 264,86 L 265,88 L 276,88 L 276,66 L 285,58 L 289,62 L 302,82 L 308,89 L 318,89 L 320,86 L 295,50 L 296,47 L 315,30 L 316,27 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 265,26 L 264,28 L 264,44 L 265,46 L 276,45 L 275,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 227,26 L 227,36 L 235,39 L 240,44 L 242,48 L 253,47 L 253,43 L 250,37 L 243,30 L 235,26 L 231,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 218,25 L 213,26 L 207,29 L 198,38 L 195,44 L 193,53 L 193,62 L 194,67 L 197,75 L 199,78 L 207,86 L 214,89 L 220,88 L 220,79 L 218,77 L 213,75 L 207,68 L 205,62 L 205,53 L 208,45 L 214,39 L 218,38 L 220,36 L 220,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 150,26 L 132,68 L 133,72 L 143,72 L 145,70 L 155,46 L 158,44 L 158,46 L 161,51 L 170,77 L 130,77 L 128,78 L 125,85 L 126,89 L 188,88 L 188,84 L 163,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 80,25 L 78,27 L 78,87 L 80,89 L 88,89 L 90,87 L 90,27 L 88,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 15,25 L 13,27 L 14,36 L 16,37 L 47,37 L 51,41 L 51,47 L 46,51 L 15,51 L 13,53 L 14,62 L 16,63 L 48,63 L 53,66 L 54,68 L 54,73 L 51,76 L 44,78 L 13,79 L 13,87 L 14,89 L 50,89 L 54,88 L 62,83 L 66,76 L 66,66 L 63,60 L 59,55 L 62,51 L 63,48 L 63,38 L 60,32 L 57,29 L 51,26 L 47,25 Z" fill="currentColor" fill-rule="evenodd"/></symbol>)
    content.sub!(/<symbol id="icon-logotype".*?<\/symbol>/m, raven_logotype)

    # Replace icon-full-logo with combined raven + wordmark
    raven_full = %q(<symbol id="icon-full-logo" viewBox="0 0 875 112"><title>Black Raven</title><g transform="translate(0,5) scale(0.28)"><path d="M 231,170 L 211,226 L 177,316 L 176,321 L 176,324 L 181,326 L 183,328 L 229,353 L 231,353 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 55,148 L 126,222 L 143,241 L 161,259 L 161,260 L 180,280 L 182,276 L 183,271 L 188,260 L 226,156 L 228,148 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 39,53 L 12,78 L 39,78 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 49,47 L 49,138 L 104,138 L 128,114 L 128,113 L 131,110 L 121,100 L 121,99 L 110,88 L 100,76 L 73,47 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 371,39 L 367,37 L 359,35 L 354,36 L 318,71 L 322,68 L 327,66 L 369,41 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 231,18 L 168,86 L 124,131 L 124,132 L 118,138 L 231,138 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 241,131 L 362,15 L 350,15 L 349,14 L 319,14 L 288,12 L 241,11 Z" fill="currentColor" fill-rule="evenodd"/></g><g transform="translate(130,0)"><path d="M 539,81 L 539,86 L 540,88 L 587,89 L 588,87 L 587,78 L 585,77 L 542,77 L 540,78 L 540,80 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 96,80 L 96,87 L 98,89 L 120,89 L 122,87 L 122,80 L 121,78 L 119,77 L 97,78 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 600,69 L 601,89 L 611,88 L 611,68 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 253,67 L 241,68 L 240,71 L 235,76 L 227,79 L 227,89 L 231,90 L 232,89 L 235,89 L 243,85 L 251,76 L 254,69 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 539,54 L 539,60 L 540,62 L 583,63 L 584,61 L 584,53 L 583,51 L 540,52 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 600,26 L 600,29 L 622,60 L 631,71 L 639,82 L 641,86 L 644,89 L 655,88 L 654,25 L 644,26 L 643,67 L 639,63 L 622,40 L 620,36 L 611,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 539,28 L 539,34 L 540,36 L 542,37 L 586,37 L 588,35 L 588,27 L 587,25 L 540,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 472,25 L 470,27 L 470,29 L 482,59 L 485,64 L 494,88 L 497,90 L 505,90 L 507,88 L 530,32 L 531,29 L 530,25 L 520,25 L 518,27 L 514,39 L 502,69 L 499,69 L 499,67 L 489,42 L 488,37 L 502,37 L 504,36 L 505,34 L 505,28 L 504,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 430,26 L 412,68 L 413,72 L 423,72 L 425,70 L 432,51 L 435,46 L 438,44 L 438,46 L 448,70 L 450,77 L 410,77 L 408,78 L 405,84 L 406,89 L 468,88 L 467,82 L 450,44 L 448,37 L 443,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 346,26 L 347,36 L 349,37 L 380,37 L 384,39 L 387,44 L 387,49 L 382,54 L 379,55 L 346,56 L 346,88 L 348,89 L 357,88 L 358,86 L 359,66 L 373,66 L 376,69 L 382,80 L 388,89 L 400,88 L 400,85 L 389,69 L 387,65 L 396,57 L 398,53 L 399,49 L 399,42 L 396,34 L 390,28 L 382,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 314,25 L 303,25 L 301,26 L 265,60 L 264,62 L 264,86 L 265,88 L 276,88 L 276,66 L 285,58 L 289,62 L 302,82 L 308,89 L 318,89 L 320,86 L 295,50 L 296,47 L 315,30 L 316,27 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 265,26 L 264,28 L 264,44 L 265,46 L 276,45 L 275,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 227,26 L 227,36 L 235,39 L 240,44 L 242,48 L 253,47 L 253,43 L 250,37 L 243,30 L 235,26 L 231,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 218,25 L 213,26 L 207,29 L 198,38 L 195,44 L 193,53 L 193,62 L 194,67 L 197,75 L 199,78 L 207,86 L 214,89 L 220,88 L 220,79 L 218,77 L 213,75 L 207,68 L 205,62 L 205,53 L 208,45 L 214,39 L 218,38 L 220,36 L 220,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 150,26 L 132,68 L 133,72 L 143,72 L 145,70 L 155,46 L 158,44 L 158,46 L 161,51 L 170,77 L 130,77 L 128,78 L 125,85 L 126,89 L 188,88 L 188,84 L 163,26 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 80,25 L 78,27 L 78,87 L 80,89 L 88,89 L 90,87 L 90,27 L 88,25 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 15,25 L 13,27 L 14,36 L 16,37 L 47,37 L 51,41 L 51,47 L 46,51 L 15,51 L 13,53 L 14,62 L 16,63 L 48,63 L 53,66 L 54,68 L 54,73 L 51,76 L 44,78 L 13,79 L 13,87 L 14,89 L 50,89 L 54,88 L 62,83 L 66,76 L 66,66 L 63,60 L 59,55 L 62,51 L 63,48 L 63,38 L 60,32 L 57,29 L 51,26 L 47,25 Z" fill="currentColor" fill-rule="evenodd"/></g></symbol>)
    content.sub!(/<symbol id="icon-full-logo".*?<\/symbol>/m, raven_full)

    File.write("'"$SPRITE"'", content)
    puts "Replaced logo symbols in SVG sprite"
  '
  echo "Patched SVG sprite with Black Raven icons"
fi

# 3. Replace logo symbols in Vite JS bundles (desktop + mobile UIs)
RAVEN_ICON='<path d="M 231,170 L 211,226 L 177,316 L 176,321 L 176,324 L 181,326 L 183,328 L 229,353 L 231,353 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 55,148 L 126,222 L 143,241 L 161,259 L 161,260 L 180,280 L 182,276 L 183,271 L 188,260 L 226,156 L 228,148 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 39,53 L 12,78 L 39,78 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 49,47 L 49,138 L 104,138 L 128,114 L 128,113 L 131,110 L 121,100 L 121,99 L 110,88 L 100,76 L 73,47 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 371,39 L 367,37 L 359,35 L 354,36 L 318,71 L 322,68 L 327,66 L 369,41 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 231,18 L 168,86 L 124,131 L 124,132 L 118,138 L 231,138 Z" fill="currentColor" fill-rule="evenodd"/><path d="M 241,131 L 362,15 L 350,15 L 349,14 L 319,14 L 288,12 L 241,11 Z" fill="currentColor" fill-rule="evenodd"/>'

for jsfile in /opt/zammad/public/assets/frontend/vite/assets/desktop-*.js /opt/zammad/public/assets/frontend/vite/assets/mobile-*.js; do
  [ -f "$jsfile" ] || continue
  if grep -q 'id="icon-logo"' "$jsfile" && ! grep -q "Black Raven" "$jsfile"; then
    ruby -e '
      content = File.read("'"$jsfile"'")
      raven = %q('"$RAVEN_ICON"')

      # Replace icon-logo (colored Zammad bird)
      raven_logo = "id=\"icon-logo\" viewBox=\"0 0 386 362\">#{raven}</symbol>"
      content.sub!(/id="icon-logo"[^>]*>.*?<\/symbol>/, raven_logo)

      # Replace icon-logo-flat (monochrome Zammad bird)
      if content.include?("icon-logo-flat")
        raven_flat = "id=\"icon-logo-flat\" viewBox=\"0 0 386 362\">#{raven}</symbol>"
        content.sub!(/id="icon-logo-flat"[^>]*>.*?<\/symbol>/, raven_flat)
      end

      File.write("'"$jsfile"'", content)
      puts "Patched #{File.basename("'"$jsfile"'")}"
    '
  fi
done

# 4. Patch chat widget HTML titles
for chathtml in /opt/zammad/public/assets/chat/index.html /opt/zammad/public/assets/chat/znuny-no-jquery-open_by_button.html; do
  if [ -f "$chathtml" ] && grep -q "Zammad Chat" "$chathtml"; then
    sed -i 's|<title>Zammad Chat</title>|<title>Black Raven Service Desk</title>|g' "$chathtml"
    echo "Patched chat title in $(basename $chathtml)"
  fi
done

# 5. Patch chat JS error messages
for chatjs in /opt/zammad/public/assets/chat/chat-no-jquery.js /opt/zammad/public/assets/chat/chat-no-jquery.min.js; do
  if [ -f "$chatjs" ] && grep -q "Zammad Chat" "$chatjs"; then
    sed -i 's|Zammad Chat:|Support Chat:|g' "$chatjs"
    echo "Patched chat messages in $(basename $chatjs)"
  fi
done

# 6. Patch error pages
for errpage in /opt/zammad/public/401.html /opt/zammad/public/403.html /opt/zammad/public/404.html /opt/zammad/public/500.html /opt/zammad/public/401-mobile.html /opt/zammad/public/403-mobile.html /opt/zammad/public/404-mobile.html /opt/zammad/public/500-mobile.html; do
  if [ -f "$errpage" ] && grep -qi "zammad" "$errpage"; then
    sed -i 's|Zammad|Black Raven Service Desk|gi' "$errpage"
    echo "Patched error page $(basename $errpage)"
  fi
done

# 7. Patch noscript fallback messages
for layout in /opt/zammad/app/views/layouts/desktop.html.erb /opt/zammad/app/views/layouts/application.html.erb /opt/zammad/public/index.html; do
  if [ -f "$layout" ] && grep -q "Turn on JavaScript to use Zammad" "$layout"; then
    sed -i 's|Turn on JavaScript to use Zammad|Turn on JavaScript to use Black Raven Service Desk|g' "$layout"
    echo "Patched noscript in $(basename $layout)"
  fi
done
