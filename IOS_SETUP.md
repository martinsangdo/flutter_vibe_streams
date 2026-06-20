# iOS Setup Notes for ClipFeed
# ─────────────────────────────────────────────────────────────────────────────

## Podfile minimum iOS version
# In ios/Podfile, set:
#   platform :ios, '13.0'   # media_kit minimum

## Info.plist — allow arbitrary HTTP loads during development
# In ios/Runner/Info.plist add:
#
#   <key>NSAppTransportSecurity</key>
#   <dict>
#     <key>NSAllowsArbitraryLoads</key>
#     <true/>
#   </dict>
#
# Remove NSAllowsArbitraryLoads before App Store submission and whitelist
# only your CDN domain with NSExceptionDomains instead.

## Background audio (optional — keeps video audio alive when screen locks)
# In Info.plist add:
#   <key>UIBackgroundModes</key>
#   <array>
#     <string>audio</string>
#   </array>

## Run after adding the above:
#   cd ios && pod install && cd ..
