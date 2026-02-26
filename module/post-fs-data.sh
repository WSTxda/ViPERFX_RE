LIBPATCH=$(cat "$MODPATH/libpatch.txt" 2>/dev/null || echo "\/vendor")
LIBDIR_REAL=$(echo "$LIBPATCH" | sed 's/\\\//\//g')

for BITNESS in lib lib64; do
  SRC="$MODPATH/system/vendor/${BITNESS}/soundfx/libv4a_re.so"
  [ -f "$SRC" ] || SRC="$MODPATH/system/${BITNESS}/soundfx/libv4a_re.so"
  [ -f "$SRC" ] || continue

  SFXDIR="${LIBDIR_REAL}/${BITNESS}/soundfx"
  [ -d "$SFXDIR" ] || continue

  if [ -f "$SFXDIR/libv4a_re.so" ]; then
    echo "[ViPER] $BITNESS/soundfx/libv4a_re.so already present (magic mount ok)"
    continue
  fi

  VTMP="/dev/viper_sfx_${BITNESS}"
  mkdir -p "$VTMP"
  mount -t tmpfs tmpfs "$VTMP"
  cp -a "$SFXDIR/." "$VTMP/" 2>/dev/null
  cp "$SRC" "$VTMP/libv4a_re.so"
  chmod 644 "$VTMP/libv4a_re.so"
  chcon u:object_r:vendor_file:s0 "$VTMP/libv4a_re.so" 2>/dev/null || true
  mount --bind "$VTMP" "$SFXDIR" \
    && echo "[ViPER] Injected: $SFXDIR/libv4a_re.so" \
    || echo "[ViPER] FAILED to inject: $SFXDIR/libv4a_re.so"
done

CFGS="$(find /odm /system /vendor -type f \( -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" \) 2>/dev/null)"

for ORIGFILE in ${CFGS}; do
  grep -q "v4a_re" "$ORIGFILE" 2>/dev/null && continue

  MOD_CFG="$MODPATH$(echo "$ORIGFILE" | sed 's|^/vendor|/system/vendor|g')"
  if [ -f "$MOD_CFG" ]; then
    PATCHED="$MOD_CFG"
  else
    PATCHED="/dev/viper_cfg_$(echo "$ORIGFILE" | tr '/' '_')"
    cp "$ORIGFILE" "$PATCHED" 2>/dev/null || continue
    case "$ORIGFILE" in
      *.conf)
        sed -i \
          -e "/v4a_standard_re {/,/}/d" \
          -e "/v4a_re {/,/}/d" \
          "$PATCHED"
        sed -i \
          -e "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }/g" \
          -e "s/^libraries {/libraries {\n  v4a_re {\n    path $LIBPATCH\/lib\/soundfx\/libv4a_re.so\n  }/g" \
          "$PATCHED"
        ;;
      *.xml)
        sed -i \
          -e "/v4a_standard_re/d" \
          -e "/v4a_re/d" \
          -e "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" \
          -e "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" \
          "$PATCHED"
        ;;
    esac
  fi

  mountpoint -q "$ORIGFILE" 2>/dev/null && continue
  mount --bind "$PATCHED" "$ORIGFILE" \
    && echo "[ViPER] Config mounted: $ORIGFILE" \
    || echo "[ViPER] Config mount FAILED: $ORIGFILE"
done
