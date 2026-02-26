#!/system/bin/sh

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

sleep 5

stop audioserver 2>/dev/null
sleep 1

if [ "$(getprop ro.board.platform)" = "kalama" ] || \
   [ "$(getprop ro.vendor.qti.soc_id)" = "519" ] || \
   getprop ro.vendor.audio.soundtrigger.vendorenhance 2>/dev/null | grep -q .; then
    stop vendor.qcom.hardware.audiohalext 2>/dev/null
    sleep 1
    start vendor.qcom.hardware.audiohalext 2>/dev/null
    sleep 1
fi

start audioserver 2>/dev/null
