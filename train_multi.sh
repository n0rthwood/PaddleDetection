fleetrun \
--selected_gpu 0,1 \
tools/train.py -c configs/rtdetr/rtdetr_r18vd_6x_coco.yml \
--eval &>logs.txt 2>&1 &