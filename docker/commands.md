# Run from ./docker:
`docker build -f ./Dockerfile.Ubuntu24AMD-build -t enowsw_contacts1.0.0__ubuntu24amd__build:1.0.0 .`

`docker tag enowsw_contacts1.0.0__ubuntu24amd__build:1.0.0 registry.gitlab.com/enowsw/contacts/v1.0.0__ubuntu24amd__build:1.0.0`

`docker login registry.gitlab.com`

`docker push registry.gitlab.com/enowsw/contacts/v1.0.0__ubuntu24amd__build:1.0.0`