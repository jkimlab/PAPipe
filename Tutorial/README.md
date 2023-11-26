# Tutorial Readme

### Run PAPipe with Docker

This file shows how to run PAPipe with Docker for test data. To run for your own data, you can easily prepare your own parameter files using [our helper webpage](http://bioinfo.konkuk.ac.kr/PAPipe/parameter_builder/) and rerun PAPipe in the Docker image.  

**1. Installing Docker Engine (Need root permission)**

Skip if your machine already has the engine ([Installation document](https://docs.docker.com/engine/install/)). 

```bash
curl -fsSL https://get.docker.com/ | sudo sh
```

**2. Adding a Docker user to the docker group (Need root permission)**

```bash
sudo usermod -aG docker $USER 	
```

**3. Downloading and loading the Docker image file** 

```bash
cd PAPipe
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/PAPipe.tar.gz
docker load -i ./PAPipe.tar.gz

#Check if the image loaded well 
docker image ls 
```

**4. Downloading the test data** 

```bash
cd TEST
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/Tutorial.tar.gz
tar -zxvf test_data.tar.gz
```

**5. Creating a docker container that mounts the directory containing Tutorial data and parameters** 

Need to use the absolute path of the "Tutorial" directory.

```bash
docker run -v [absolute path of .../PAPipe/Tutorial/]:/RUN_DOCKER/  -it pap_docker:latest
```

**6. Running PAPipe in the Docker container** 

```bash
# Run in the docker container
cd /RUN_DOCKER/run_tutorial
python3 /PAPipe/bin/main.py  -P ./main_param.txt  -I ./main_input.txt -A ./main_sample.txt &> ./log
```

**7. Generating HTML pages for browsing analysis results** 

```bash
# Run in the docker container
perl /PAPipe/bin/html/webEnvSet.pl ./out &> webenvset.log # ./out is the output directory set in the PAPipe parameter file
cd ./out/web/
perl /PAPipe/bin/html/prep_html.pl ./ &> ./webgen.log
```
**8. Browsing analysis results** 

Use own familiar methods, take the generated whole \[web\] directory to the local 

```bash
# Run on the local terminal 
# For example (using scp): 
scp user@host_address:[web directory path in server] [proper local path to download the population analysis results]
```

