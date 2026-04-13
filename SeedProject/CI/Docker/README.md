# Docker


Use [`./build_image.py`](./build_image.py) to build and push images to the Docker image registry configured in [`../../meta/CI.json`](../../meta/CI.json):
```bash
python ./build_image.py --help
```
[`This directory`](.) contains Dockerfiles. They must be fed to the [`./build_image.py`](./build_image.py) every time they are changed before triggering CI.