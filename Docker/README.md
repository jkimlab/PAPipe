# DOCKER Readme

### Run PAPipe with Docker

This file shows how to run PAPipe with Docker for a test data. To run for your own data, you can easily prepare your own parameter files using [our helper webpage](http://bioinfo.konkuk.ac.kr/PAPipe/parameter_builder/) and rerun PAPipe in the Docker image.  

**1. Installing Docker Engine (Need root permission)**

Skip if your machine already has the engine ([Installation document](https://docs.docker.com/engine/install/)). 

```bash
curl -fsSL https://get.docker.com/ | sudo sh
```

**2. Adding a Docker user to the docker group (Need root permission)**

```bash
sudo usermod -aG docker $USER 	
```

**3. Cloning the PAPipe git repository**

```bash
git clone https://github.com/jkimlab/PAPipe
```

**4. Downloading and loading the Docker image file** 

```bash
cd PAPipe
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/PAPipe.tar.gz
docker load -i ./PAPipe.tar.gz

#Check if the image loaded well 
docker image ls 
```

**5. Downloading the test data** 

```bash
cd TEST
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/test_data.tar.gz
tar -zxvf test_data.tar.gz
```

**6. Creating a docker container that mounts the directory of the test data** 

Need to use the absolute path of the "TEST" directory.

```bash
docker run -v [absolute path of .../PAPipe/TEST/]:/RUN_DOCKER/  -it pap_docker:latest
```

**7. Running PAPipe in the Docker container** 

```bash
# Run in the docker container
cd /RUN_DOCKER/docker_test
python3 /PAPipe/bin/main.py  -P ./main_param.txt  -I ./main_input.txt -A ./main_sample.txt &> ./log
```

**8. Generating HTML pages for browsing analysis results** 

```bash
# Run in the docker container
perl /PAPipe/bin/webEnvSet.pl ./out &> webenvset.log # ./out is the output directory set in the PAPipe parameter file
cd ./out/web/
python3 /PAPipe/bin/html/html/select_input.py /PAPipe/bin/html/html/pre_index.html &> ./webgen.log
```
**9. Browsing analysis results** 

Add description here.
