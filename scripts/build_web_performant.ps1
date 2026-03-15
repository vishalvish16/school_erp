# Build Flutter web with HTML renderer for smoother animations on lower-end devices.
# Use this if the default CanvasKit build feels laggy (dropdowns, sidebar collapse, etc.)
# Usage: .\scripts\build_web_performant.ps1

flutter build web --web-renderer html
