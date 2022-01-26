## Installation
### Docker Image
We provide a [docker](https://www.docker.com) image that all requirements are pre-installed at [skkusal/symtuner](https://hub.docker.com/repository/docker/skkusal/symtuner). 
To install [docker](https://www.docker.com) on your system, please follow the instructions at [docker installation](https://docs.docker.com/engine/install). 
After the [docker](https://www.docker.com) is successfully installed, you can download and use our tool by following the commands below:
```bash
$ docker pull skkusal/symtuner
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
```
Since KLEE, the symbolic executor, needs a big stack size,
we recommend you to set an unlimited stack size by `--ulimit='stack=-1:-1'`.
