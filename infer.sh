export CUDA_VISIBLE_DEVICES=0

python tools/infer.py \
-c configs/rtdetr/rtdetr_r18vd_6x_coco.yml \
-o use_gpu=true  weights=output/best_model/model.pdparams \
--infer_img="demo/16331709113253_.pic.jpg"