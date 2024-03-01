python tools/export_model.py -c configs/rtdetr/rtdetr_r18vd_6x_coco.yml \
              -o weights=output/best_model/model.pdparams trt=True \
              --output_dir=output_inference

paddle2onnx --model_dir output_inference/rtdetr_r18vd_6x_coco \
            --model_filename model.pdmodel \
            --params_filename model.pdiparams \
            --opset_version 16 \
            --save_file rtdetr_r18vd_6x_coco.onnx