#!/usr/bin/env sh
set -e

if [ -z $BENCH_MOUNTPOINT ]; then
    BENCH_MOUNTPOINT=/tmp
fi

if [ -z $FIO_SIZE ]; then
    FIO_SIZE=2G
fi

if [ -z $FIO_OFFSET_INCREMENT ]; then
    FIO_OFFSET_INCREMENT=500M
fi

if [ -z $FIO_DIRECT ]; then
    FIO_DIRECT=1
fi

if [ -z $DEL ]; then
    DEL=1
fi

if [ -z $IO_ENGINE ]; then
    IO_ENGINE=libaio
fi

if [ -z $NUMJOBS ]; then
    NUMJOBS=1
fi

if [ -z $RUNTIME ]; then
    RUNTIME=100
fi

echo Working dir: $BENCH_MOUNTPOINT
echo

if [ "$1" = 'fio' ]; then

    echo Testing Read IOPS...
    READ_IOPS=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --gtod_reduce=1 --name=read_iops --filename=$BENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=64 --size=$FIO_SIZE -numjobs=$NUMJOBS --readwrite=randread --time_based --ramp_time=2s --runtime=$RUNTIME)
    echo "$READ_IOPS"
    READ_IOPS_VAL=$(echo "$READ_IOPS"|grep -E 'read ?:'|grep -Eoi 'IOPS=[[:space:]0-9k.]+'|cut -d'=' -f2)
    echo
    echo

    echo Testing Write IOPS...
    WRITE_IOPS=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --gtod_reduce=1 --name=write_iops --filename=$BENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=64 --size=$FIO_SIZE -numjobs=$NUMJOBS --readwrite=randwrite --time_based --ramp_time=2s --runtime=$RUNTIME)
    echo "$WRITE_IOPS"
    WRITE_IOPS_VAL=$(echo "$WRITE_IOPS"|grep -E 'write:'|grep -Eoi 'IOPS=[[:space:]0-9k.]+'|cut -d'=' -f2)
    echo
    echo

    echo Testing Read Bandwidth...
    READ_BW=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --gtod_reduce=1 --name=read_bw --filename=$BENCH_MOUNTPOINT/fiotest --bs=128K --iodepth=64 --size=$FIO_SIZE -numjobs=$NUMJOBS --readwrite=randread --time_based --ramp_time=2s --runtime=$RUNTIME)
    echo "$READ_BW"
    READ_BW_VAL=$(echo "$READ_BW"|grep -E 'read ?:'|grep -Eoi 'BW=[[:space:]0-9GMKiBs/.]+'|cut -d'=' -f2)
    echo
    echo

    echo Testing Write Bandwidth...
    WRITE_BW=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --gtod_reduce=1 --name=write_bw --filename=$BENCH_MOUNTPOINT/fiotest --bs=128K --iodepth=64 --size=$FIO_SIZE -numjobs=$NUMJOBS --readwrite=randwrite --time_based --ramp_time=2s --runtime=$RUNTIME)
    echo "$WRITE_BW"
    WRITE_BW_VAL=$(echo "$WRITE_BW"|grep -E 'write:'|grep -Eoi 'BW=[[:space:]0-9GMKiBs/.]+'|cut -d'=' -f2)
    echo
    echo

    if [ "$QUICK_BENCH" == "" ] || [ "$QUICK_BENCH" == "no" ]; then
        echo Testing Read Latency...
        READ_LATENCY=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --name=read_latency --filename=$BENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=4 --size=$FIO_SIZE --readwrite=randread --time_based --ramp_time=2s --runtime=$RUNTIME)
        echo "$READ_LATENCY"
        READ_LATENCY_VAL=$(echo "$READ_LATENCY"|grep -E '\blat.*avg'|grep -Eoi 'avg=[[:space:]0-9.]+'|cut -d'=' -f2)
        READ_LATENCY_VAL=$READ_LATENCY_VAL$(echo "$READ_LATENCY"|grep -E '\blat.*avg'|awk '{gsub("\\(|\\)|:","",$2);print $2}')
        echo
        echo

        echo Testing Write Latency...
        WRITE_LATENCY=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --name=write_latency --filename=$BENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=4 --size=$FIO_SIZE --readwrite=randwrite --time_based --ramp_time=2s --runtime=$RUNTIME)
        echo "$WRITE_LATENCY"
        WRITE_LATENCY_VAL=$(echo "$WRITE_LATENCY"|grep -E '\blat.*avg'|grep -Eoi 'avg=[[:space:]0-9.]+'|cut -d'=' -f2)
        WRITE_LATENCY_VAL=$WRITE_LATENCY_VAL$(echo "$WRITE_LATENCY"|grep -E '\blat.*avg'|awk '{gsub("\\(|\\)|:","",$2);print $2}')
        echo
        echo

        echo Testing Read/Write Mixed...
        RW_MIX=$(fio --randrepeat=0 --verify=0 --ioengine=$IO_ENGINE --direct=$FIO_DIRECT --gtod_reduce=1 --name=rw_mix --filename=$BENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=64 --size=$FIO_SIZE --readwrite=randrw --rwmixread=75 --time_based --ramp_time=2s --runtime=$RUNTIME)
        echo "$RW_MIX"
        RW_MIX_R_IOPS=$(echo "$RW_MIX"|grep -E 'read ?:'|grep -Eoi 'IOPS=[[:space:]0-9k.]+'|cut -d'=' -f2)
        RW_MIX_W_IOPS=$(echo "$RW_MIX"|grep -E 'write:'|grep -Eoi 'IOPS=[[:space:]0-9k.]+'|cut -d'=' -f2)
        echo
        echo
    fi

    echo All tests complete.
    echo
    echo ==================
    echo = Dbench Summary =
    echo ==================
    echo "Random Read/Write IOPS: $READ_IOPS_VAL/$WRITE_IOPS_VAL"
    echo "Sequential Read/Write BW: $READ_BW_VAL / $WRITE_BW_VAL"
    if [ -z $QUICK_BENCH ] || [ "$QUICK_BENCH" == "no" ]; then
        echo "Average Latency Read/Write: $READ_LATENCY_VAL/$WRITE_LATENCY_VAL"
        echo "Mixed Random Read/Write IOPS: $RW_MIX_R_IOPS/$RW_MIX_W_IOPS"
    fi

    if [ $DEL == 1 ]; then
        rm $BENCH_MOUNTPOINT/fiotest
    fi
    exit 0
fi

exec "$@"
