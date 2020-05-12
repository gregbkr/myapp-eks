# ECS demo

- **Description**: Deploy an app in EKS (kubernetes containers)
- **Why**: for app that can run in container
- **Network access**: Application Load-balancer (ALB)
- **CICD**: codepipeline code injection in github
- **Elasticity**: EKS
- **Update infra**: auto for master, manual for worker
- **Deploy infra**: GUI for now
- **The app**: a simple hello world: https://github.com/gregbkr/hello

# Deploy

## Setup EKS
- Create an EKS with: 
```
export TAG=hello-terra-gg <-- choose a unique prefix

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

## Check EKS
- Setup your kubeconfig: `aws eks --region eu-west-1 update-kubeconfig --name hello1`
- Test: `kubectl get svc`
- Deploy hello app: `kubectl apply -f hello/hello.yml`
- Test the app by curling the public DNS `EXTERNAL-IP:PORT` listed here: `kubectl get svc`
- Curl: `curl acc43f4be4e5311eab2ed0e7ccd0f45b-1073317507.eu-west-3.elb.amazonaws.com:8080`
- Delete deploy: `kubectl delete -f hello/hello.yml`

## CICD
- Edit your [buildspec](https://github.com/gregbkr/hello/hello-template.yml) variable 
- Deploy CodeBuild and CodePipeline: 
```
cd terraform
export GITHUBTOKEN=[your_token_here]'
terraform apply -var gitHubToken=$GITHUBTOKEN -var tag=$TAG
```

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

- Find the urls of the services: `kubectl get svc`
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