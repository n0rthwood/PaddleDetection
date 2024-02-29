export CUDA_VISIBLE_DEVICES=0,1
python -m paddle.distributed.launch --gpus 0,1 tools/train.py -c /opt/workspace/PaddleDetection/configs/rtdetr/rtdetr_r18vd_6x_coco.yml --eval