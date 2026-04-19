SKIPUNZIP=1

# Extract module files
unzip -qjo "$ZIPFILE" -x 'META-INF/*' 'customize.sh' -d "$MODPATH" >&2

ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "   DoseBreaker"
ui_print "   by Vetheon @ Lyrinox Technologies"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""

# -----------------------------
# Root Manager Detection
# -----------------------------
if [ -n "$APATCH_VER" ]; then
    ROOT_MGR="APatch"
elif [ -n "$KSU_VER" ]; then
    ROOT_MGR="KernelSU"
elif [ -n "$MAGISK_VER" ]; then
    ROOT_MGR="Magisk"
else
    ROOT_MGR="Unknown"
fi

# -----------------------------
# Finish
# -----------------------------
ui_print ""
ui_print "  Root manager: $ROOT_MGR"
ui_print ""
ui_print "  ✓ Installation complete"
ui_print "  ✓ Runtime enforcement enabled"
ui_print ""
ui_print "  ⚠ Reboot required!"
ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
ui_print "  If this module helped you,"
ui_print "  consider sponsoring us on GitHub!"
ui_print ""
ui_print "  github.com/sponsors/LyrinoxTechnologies"
ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
