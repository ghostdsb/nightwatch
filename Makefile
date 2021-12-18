VERSION_DEV = 0.1.3_dev-staging
VERSION_PROD = 0.1.0

dev-release:
	mix deps.get
	mix compile
	mix release --overwrite

prod-release:
	mix deps.get
	MIX_ENV=prod mix compile
	MIX_ENV=prod mix release --overwrite

builddockerdev: 
	docker build --file dev.Dockerfile --tag ghostdsbdocker/nightwatch .
	docker tag ghostdsbdocker/nightwatch ghostdsbdocker/nightwatch:$(VERSION_DEV)

builddocker: 
	docker build --file Dockerfile --tag ghostdsbdocker/nightwatch .
	docker tag ghostdsbdocker/nightwatch ghostdsbdocker/nightwatch:$(VERSION_PROD)

stopdockerdev:
	docker container stop nightwatch-$(VERSION_DEV)

rundockerdev: builddockerdev
	docker run --name nightwatch-$(VERSION_DEV) --publish 4000:4000 --detach --env PORT=4000 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} ghostdsbdocker/nightwatch:$(VERSION_DEV)

rundocker:	
	docker run --name nightwatch-$(VERSION_PROD) --publish 4000:4000 --detach --env PORT=4000 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} ghostdsbdocker/nightwatch:$(VERSION_PROD)

pushdockerdev: builddockerdev
	docker push ghostdsbdocker/nightwatch:$(VERSION_DEV)

pushdockerprod: builddockerprod
	docker push ghostdsbdocker/nightwatch:$(VERSION_PROD)

create-deployment:
	minikube kubectl -- create -f ./k8s/deployment.yaml