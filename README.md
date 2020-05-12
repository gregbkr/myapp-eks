# MyApp: HA container in EKS (AWS managed kubernetes)

## Overview
This setup will deploy a redundant helloworld container on ECS fargate, with automatic CI/CD from AWS.

More info: you can find an overview of that setup on my [blog](https://greg.satoshi.tech/ecs)

### Infra
![Infra](./.github/images/myapp-ecs-infra.png)

- Cloud: AWS
- [EKS](https://aws.amazon.com/eks): managed Kubernetes container orchestrator (on 2 availability zones for redundancy)
- [ECR](https://aws.amazon.com/ecr): container registry to store hello image
- App: a simple hello world in nodejs (folder `hello`)
- Code source: github
- Deployment: [Terraform](https://www.terraform.io/) describes all components to be deployed. One command line will setup the infra
- CI/CD: [Codepipeline](https://aws.amazon.com/codepipeline) to buid and deploy the orchestrator EKS, the pipeline


### CI/CD flow diagram

![CI/CD](./.github/images/myapp-ecs-cicd.png)

A simple `git push` from a developer in Github will launch the whole CI/CD process. Docker image will build and containers in EKS will be updated to run that new image without any downtime.

# Deploy

### Prerequisites
Please setup on your laptop:
- AWS cli and AWS account to deploy in `eu-west-1`
- Docker and Compose
- Github personal token with `admin:repo_hook, repo` rights from [here](https://github.com/settings/tokens)

### Test app on your laptop
Check the app locally:
```
cd hello
docker-compose up -d
curl localhost 8080
```

## Deploy to AWS
- Set a unique project prefix and your github token:
```
cd terraform
export TAG=hello-protos   <-- please change to your prefix!
export GITHUBTOKEN=xxxx   <-- You token here
nano buildspec-eks.yml    <-- edit build vars
```
- Deploy EKS and CodePipeline: 
```
terraform init
terraform apply -var gitHubToken=$GITHUBTOKEN -var tag=$TAG
```

## Check EKS
- Cd `cd ..`
- Setup your kubeconfig: `aws eks --region eu-west-1 update-kubeconfig --name $TAG`
- Test: `kubectl get svc`
- Deploy hello app (using dockerhub hello image): `kubectl apply -f hello/hello.yml` 
- Test the app by curling the public DNS `EXTERNAL-IP:PORT` listed here: `kubectl get all`
- Curl: `curl acc43f4be4e5311eab2ed0e7ccd0f45b-1073317507.eu-west-3.elb.amazonaws.com:8080`
- Delete deploy: `kubectl delete -f hello/hello.yml`

## CI/CD
- For CodeBuild IAM role to be able to deploy to EKS, you need to add a permission in EKS as described [here](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- Backup the configmap first: `kubectl get -o yaml -n kube-system configmap/aws-auth > aws-auth.yml`
- Edit it: `kubectl edit -n kube-system configmap/aws-auth`
- And replace with your build role ARN and add the block below the `mapUsers: |` section :
```
    - userarn: arn:aws:iam::[YOUR_ACCOUNT_ID]:role/[YOUR_TAG]-build-role
      username: codebuild
      groups:
        - system:masters
```

- Try a new build. If sucessful: `kubectl get svc`
```
kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)          AGE
hello-dev    LoadBalancer   10.100.60.248   ad0039cfa4f3911ea9cc00e382602d1a-1499677234.eu-west-3.elb.amazonaws.com   8080:31028/TCP   25m
hello-prod   LoadBalancer   10.100.137.92   ac36f17644f3911ea9cc00e382602d1a-391888307.eu-west-3.elb.amazonaws.com    8080:31017/TCP   25m
kubernetes   ClusterIP      10.100.0.1      <none>                                                                    443/TCP          4h37m

curl ad0039cfa4f3911ea9cc00e382602d1a-1499677234.eu-west-3.elb.amazonaws.com:8080
Hello world *DEV* v3.5 from server: hello-dev-5cff8d7f5-fcmch

curl ac36f17644f3911ea9cc00e382602d1a-391888307.eu-west-3.elb.amazonaws.com:8080
Hello world *PROD* v3.2 from server: hello-prod-5ff4c8b79f-hfbrh%
```

# Destroy all
- Delete the EKS cluster (carefull, ALL will be deleted): `eksctl delete cluster $TAG`

# Todo

- Only 1 Loadbalancer
- Env var for branch
- Blue green

# Annexes

- Deploy with eksctl:
```
eksctl create cluster \
--name $TAG \
--version 1.14 \
--nodegroup-name standard-workers \
--node-type t2.medium \
--nodes 2 \
--nodes-min 2 \
--nodes-max 3 \
--node-ami auto
```
- To scale up the node: `eksctl scale nodegroup --cluster hello-terra-bkr --name standard-workers --nodes 4`
