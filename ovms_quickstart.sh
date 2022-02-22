#!/bin/bash -xe

docker container ls --all

# Step 0: Clean up
#docker container rm $(docker container ls --all -q)
#docker rmi 	$(docker images -a -q)

# Step 2: Download and Build the OpenVINO Model Server
docker pull openvino/model_server:latest

# Step 3: Provide a model
curl --create-dirs \
  https://download.01.org/opencv/2021/openvinotoolkit/2021.1/open_model_zoo/models_bin/1/face-detection-retail-0004/FP32/face-detection-retail-0004.xml \
  https://download.01.org/opencv/2021/openvinotoolkit/2021.1/open_model_zoo/models_bin/1/face-detection-retail-0004/FP32/face-detection-retail-0004.bin \
  -o model/1/face-detection-retail-0004.xml \
  -o model/1/face-detection-retail-0004.bin

# Step 4: Start the Model Server Container
docker run -d -u $(id -u):$(id -g) \
  -v $(pwd)/model:/models/face-detection \
  -p 9000:9000 openvino/model_server:latest \
  --model_path /models/face-detection --model_name face-detection --port 9000 --plugin_config '{"CPU_THROUGHPUT_STREAMS": "1"}' \
  --shape auto

# Step 5: Prepare the Example Client Components 
curl https://raw.githubusercontent.com/openvinotoolkit/model_server/master/example_client/client_utils.py \
  -o client_utils.py \
  https://raw.githubusercontent.com/openvinotoolkit/model_server/master/example_client/face_detection.py \
  -o face_detection.py \
  https://raw.githubusercontent.com/openvinotoolkit/model_server/master/example_client/client_requirements.txt \
  -o client_requirements.txt

# Step 6: Download Data for Inference
curl --create-dirs \
  https://raw.githubusercontent.com/openvinotoolkit/model_server/v2021.4.2/example_client/images/people/people1.jpeg \
  -o images/people1.jpeg

# Step 7: Run Inference
pip install -r client_requirements.txt
mkdir results
python face_detection.py --batch_size 1 --width 600 --height 400 --input_images_dir images --output_dir results

