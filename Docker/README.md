# DOCKER Readme

### Run PAPipe with Docker

**Install docker and get ready to load PAPipe docker image**

[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

```bash
curl -fsSL https://get.docker.com/ | sudo sh
sudo usermod -aG docker $USER 	# adding user to the “docker” group
```

**Git clone PAPipe repository**

```bash
glt clone https://github.com/nayoung9/PAPipe
```

**You can load the image from the .tar file ** 

```bash
cd PAPipe/Docker/
gzip -d PAPipe.tar.gz
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
