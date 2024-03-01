import onnxruntime
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import time  # Import the time module

# Load the ONNX model
onnx_file_name = "output_inference/rtdetr_r18vd_6x_coco.onnx"
original_img="demo/16331709113253_.pic.jpg"
ort_session = onnxruntime.InferenceSession(onnx_file_name)

# Function to preprocess the image
def preprocess_image(image_path):
    original_image = Image.open(image_path).convert("RGB")
    original_size = np.array(original_image.size, dtype=np.float32)  # Original size [width, height]

    # Resize image to 640x640
    input_image = original_image.resize((640, 640), Image.BILINEAR)
    input_tensor = np.array(input_image, dtype=np.float32) / 255.0  # Normalize to [0, 1]
    input_tensor = np.transpose(input_tensor, [2, 0, 1])  # Change data layout from HWC to CHW
    input_tensor = np.expand_dims(input_tensor, axis=0)  # Add batch dimension

    return input_tensor, original_size

# Prepare inputs
input_img, original_size = preprocess_image(original_img)
im_shape = np.expand_dims(original_size, axis=0)  # Add batch dimension
scale_factor = np.ones((1, 2), dtype=np.float32)  # Assuming no scaling, adjust if necessary

# Prepare the input dictionary
ort_inputs = {
    ort_session.get_inputs()[1].name: input_img,  # 'image'
    ort_session.get_inputs()[0].name: im_shape,  # 'im_shape'
    ort_session.get_inputs()[2].name: scale_factor  # 'scale_factor'
}

# Run inference

# Start timing
start_time = time.time()

# Run inference 100 times
for _ in range(100):
    ort_output = ort_session.run(None, ort_inputs)

# End timing
end_time = time.time()

# Calculate and print the total duration
total_duration = end_time - start_time
total_duration = total_duration*1000
print(f"Total duration for 100 inferences: {total_duration:.2f} ms seconds")

# Optionally, calculate and print the average duration per inference
average_duration = total_duration / 100
print(f"Average duration per inference: {average_duration:.4f} ms seconds")
# print("Output shape:", ort_output.shape)
# print("Output content:", ort_output)
# Assuming ort_output contains bounding boxes and labels in a specific format
# You might need to adjust this part based on the actual output format of your model

def draw_bbox(image, bboxes, catid2name, threshold=0.1):
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()

    print(f"Number of detections: {len(bboxes)}")  # Diagnostic print

    for bbox in bboxes:
        class_id, confidence, xmin, ymin, xmax, ymax = bbox

        #print(f"Detection: Class ID: {class_id}, Confidence: {confidence}")  # Diagnostic print

        if confidence < threshold:
            continue

        class_name = catid2name.get(int(class_id), str(class_id))
        draw.rectangle([(xmin, ymin), (xmax, ymax)], outline='red', width=2)
        label = f"{class_name} {confidence:.2f}"
        draw.text((xmin, ymin), label, fill='red', font=font)

    return image

# Example usage
catid2name = {0: 'single', 1: 'Class2'}  # Example class ID to name mapping
# Assuming ort_output is your model output with shape (300, 6)
image = Image.open(original_img)  # Load your original image
image = draw_bbox(image, ort_output, catid2name, threshold=0.1)

# Display or save the result
#original_image.show()
image.save("output_image.jpg")
