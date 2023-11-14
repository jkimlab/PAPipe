# DOCKER Readme

### Run PAPipe with Docker

**Installing Docker Engine (Need root permission)**

Skip if your machine already has the engine ([Installation document](https://docs.docker.com/engine/install/)). 

```bash
curl -fsSL https://get.docker.com/ | sudo sh
```

**Adding a Docker user to the docker group (Need root permission)**

```bash
sudo usermod -aG docker $USER 	
```

**Cloning the PAPipe git repository**

```bash
git clone https://github.com/jkimlab/PAPipe
```

**Downloading and loading the Docker image file** 

```bash
cd PAPipe
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/PAPipe.tar.gz
docker load -i ./PAPipe.tar.gz

#Check if the image loaded well 
docker image ls 
```

**Downloading the test data** 

```bash
cd TEST
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/test_data.tar.gz
tar -zxvf test_data.tar.gz
```

**Creating a docker container that mounts the directory of the test data** 

Need to use the absolute path of the "TEST" directory.

```bash
docker run -v [absolute path of .../PAPipe/TEST/]:/RUN_DOCKER/  -it pap_docker:latest
```

**Run PAPipe in the docker container** 

```bash
#on the docker container
cd /RUN_DOCKER/docker_test
python3 /PAPipe/bin/main.py  -P ./main_param.txt  -I main_input.txt -A main_sample.txt &> log
```

**Run additional commands to generate local result browser** 

```bash
#on the docker container
cd /RUN_DOCKER/docker_test/
perl /PAPipe/bin/webEnvSet.pl ./out &> webenvset.log
cd ./out/web/
/PAPipe/bin/html/html/select_input.py /PAPipe/bin/html/html/pre_index.html &> webgen.log
```
