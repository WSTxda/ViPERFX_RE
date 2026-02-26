LIBPATCH=$(cat "$MODPATH/libpatch.txt")
LIBDIR_REAL=$(echo "$LIBPATCH" | sed 's/\\\//\//g')

CFGS="$(find /odm /system /vendor -type f \( -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" \) 2>/dev/null)"

for FILE in ${CFGS}; do
  [ -w "$FILE" ] || continue
  case $FILE in
    *.conf)
        sed -i \
          -e "/v4a_standard_re {/,/}/d" \
          -e "/v4a_re {/,/}/d" \
          "$FILE"
        sed -i \
          -e "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }/g" \
          -e "s/^libraries {/libraries {\n  v4a_re {\n    path $LIBPATCH\/lib\/soundfx\/libv4a_re.so\n  }/g" \
          "$FILE"
        ;;
    *.xml)
        sed -i \
          -e "/v4a_standard_re/d" \
          -e "/v4a_re/d" \
          -e "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" \
          -e "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" \
          "$FILE"
        ;;
  esac
done

if [ -d "/odm/etc/" ] && [ -f "$MODPATH/odm/etc/audio_effects.xml" ]; then
  if ! mountpoint -q /odm/etc/audio_effects.xml 2>/dev/null; then
    echo "[ViPER] Bind mount: /odm/etc/audio_effects.xml"
    mount --bind "$MODPATH/odm/etc/audio_effects.xml" /odm/etc/audio_effects.xml
  fi
fi

for BITNESS in lib lib64; do
  SRC="$MODPATH/system/vendor/${BITNESS}/soundfx/libv4a_re.so"
  [ -f "$SRC" ] || SRC="$MODPATH/system/${BITNESS}/soundfx/libv4a_re.so"
  [ -f "$SRC" ] || continue

  DST="${LIBDIR_REAL}/${BITNESS}/soundfx/libv4a_re.so"
  DSTDIR="${LIBDIR_REAL}/${BITNESS}/soundfx"

  if [ ! -f "$DST" ]; then
    echo "[ViPER] Fallback: copiando $SRC → $DST"
    mkdir -p "$DSTDIR"
    cp "$SRC" "$DST"
    chmod 644 "$DST"
    chcon u:object_r:vendor_file:s0 "$DST" 2>/dev/null || restorecon "$DST" 2>/dev/null || true
  fi
done
