# DOCKER Readme

### Run PAPipe with Docker

**Install docker and get ready to load the PAPipe docker image (you need root permission)**

[Install Docker Engine on Various OS](https://docs.docker.com/engine/install/) (skip if your machine already has the engine)

```bash
curl -fsSL https://get.docker.com/ | sudo sh
sudo usermod -aG docker $USER 	# adding user to the “docker” group
```

**Git clone PAPipe repository**

```bash
git clone https://github.com/jkimlab/PAPipe
```

**Download Tutorial data and get ready to run** 

```bash
cd PAPipe/TEST/
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/test_data.tar.gz
tar -zxvf test_data.tar.gz
```

**Download .tar file and load the image** 

```bash
wget http://bioinfo.konkuk.ac.kr/PAPipe/bin/PAPipe.tar
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
