# Run PAPipe with a small test data

**1. Installing the Docker Engine (Need root permission)**

Skip if your machine already has the engine ([Installation document](https://docs.docker.com/engine/install/)). 

```bash
curl -fsSL https://get.docker.com/ | sudo sh
```

**2. Adding a Docker user to the docker group (Need root permission)**

Skip if your account is already in the docker group

```bash
sudo usermod -aG docker $USER 	
```

**3. Downloading and loading the Docker image file** 

```bash
wget http://bioinfo.konkuk.ac.kr/PAPipe/PAPipe.tar.gz    # Download the Docker image file
docker load -i ./PAPipe.tar.gz    # Load the Docker image file
docker image ls    # Check if the image loaded well ("REPOSITORY:pap_docker, TAG:latest" must be shown)
```

**4. Downloading the test data** 

```bash
wget http://bioinfo.konkuk.ac.kr/PAPipe/test_data.tar.gz
tar -zxvf test_data.tar.gz
```

**5. Creating a docker container that mounts the directory containing the test data** 

Need to use the absolute path of the "test_data" directory.

```bash
docker run -v [absolute path of the "test_data" directory]:/RUN_DOCKER/  -it pap_docker:latest
```

**6. Running PAPipe in the Docker container** 

```bash
# Run in the docker container
cd /RUN_DOCKER
python3 /PAPipe/bin/main.py  -P ./main_param.txt  -I ./main_input.txt -A ./main_sample.txt &> ./log
```

**7. Generating HTML pages for browsing analysis results** 

```bash
# Run in the docker container
perl /PAPipe/bin/html/webEnvSet.pl ./out &> webenvset.log # ./out is the output directory set in the "main_param.txt" file
cd ./out/web/
perl /PAPipe/bin/html/prep_html.pl ./ &> ./webgen.log
```



