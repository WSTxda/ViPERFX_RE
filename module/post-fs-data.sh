LIBPATCH=$(cat "$MODPATH/libpatch.txt")
CFGS="$(find /odm /system /vendor -type f \( -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" \))"
for FILE in ${CFGS}; do
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
    echo "Binding audio_effects.xml to odm partition..."
    mount --bind "$MODPATH/odm/etc/audio_effects.xml" /odm/etc/audio_effects.xml
  fi
fi


if [ ! -d "/data/adb/magisk" ]; then
  echo "[ViPER] Raiz não-Magisk detectada (KernelSU/APatch), aplicando bind mounts manuais..."

  LIBDIR_REAL=$(echo "$LIBPATCH" | sed 's/\\\//\//g')

  for BITNESS in lib lib64; do
    SRC="$MODPATH/system/vendor/${BITNESS}/soundfx/libv4a_re.so"
    [ ! -f "$SRC" ] && SRC="$MODPATH/system/${BITNESS}/soundfx/libv4a_re.so"

    DST="${LIBDIR_REAL}/${BITNESS}/soundfx/libv4a_re.so"
    DSTDIR="${LIBDIR_REAL}/${BITNESS}/soundfx"

    if [ -f "$SRC" ]; then
      if [ ! -d "$DSTDIR" ]; then
        echo "[ViPER] Criando $DSTDIR"
        mkdir -p "$DSTDIR"
        chcon --reference="${LIBDIR_REAL}/${BITNESS}" "$DSTDIR" 2>/dev/null || true
      fi

      if [ ! -f "$DST" ]; then
        echo "[ViPER] Copiando $SRC para $DST"
        cp "$SRC" "$DST"
        chmod 644 "$DST"
        restorecon "$DST" 2>/dev/null || chcon u:object_r:vendor_file:s0 "$DST" 2>/dev/null || true
      fi

      if ! mountpoint -q "$DST" 2>/dev/null; then
        mount --bind "$SRC" "$DST" \
          && echo "[ViPER] Bind mount aplicado: $DST" \
          || echo "[ViPER] Falha no bind mount: $DST"
      fi
    fi
  done

  for CFG_FILE in ${CFGS}; do
    MOD_CFG="$MODPATH$(echo "$CFG_FILE" | sed 's|^/vendor|/system/vendor|g')"
    if [ -f "$MOD_CFG" ] && ! mountpoint -q "$CFG_FILE" 2>/dev/null; then
      mount --bind "$MOD_CFG" "$CFG_FILE" \
        && echo "[ViPER] Config bind mount: $CFG_FILE" \
        || echo "[ViPER] Falha config bind mount: $CFG_FILE"
    fi
  done
fi
