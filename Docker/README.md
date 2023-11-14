# DOCKER Readme

### Run PAPipe with Docker

**Installing Docker Engine (Need root permission)**

Skip if your machine already has the engine ([Instllation documentation](https://docs.docker.com/engine/install/)). 

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

**Downloading the test data** 

```bash
cd PAPipe/TEST/
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/test_data.tar.gz
tar -zxvf test_data.tar.gz
```

**Downloading and loading the Docker image file** 

```bash
# Go back to the top directory of PAPipe
cd ../

wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/PAPipe.tar.gz
docker load -i ./PAPipe.tar

#Check if the image load well 
docker image ls 
```

**Create docker container mounting the tutorial data directory** 

```bash
cd PAPipe/TEST/
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
