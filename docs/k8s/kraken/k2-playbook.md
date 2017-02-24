## 쿠버네티스 클러스터 생성 워크플로우 요약

### kraken.config
설정파일을 읽어들입니다. 정의되지 않은 경우 기본값을 사용합니다. 클러스터 이름이나 토큰에 사용할 난수를 생성합니다.

### kraken.cluster_common
전체 노드가 부트될 때 공통적으로 사용할 cloud-init 디렉토리와 파일을 준비합니다. 네트워크 환경 변수, CA 키 및 인증서, 인증서 설치, coreos 업데이트, 볼륨 포맷 및 마운트, docker 마운트 대기 등의 작업을 준비합니다.

### kraken.etcd.docker
etcd 노드가 부트될 때 사용할 cloud-init 파일을 준비합니다. etcd 및 ssl 설정과 관련된 준비를 합니다. 

### kraken.master.docker
master 노드가 부트될 때 사용할 cloud-init 파일을 준비합니다. 서비스 계정을 생성하고 api-server, controller-manager, kube-proxy, scheduler, kubelet 설정 및 설치를 준비합니다. 

### kraken.node.docker
worker 노드가 부트될 때 사용할 cloud-init 파일을 준비합니다. kube-proxy, kubelet, worker-ssl 의 설정 및 설치를 준비합니다.

### kraken.assembler
준비한 파일들을 모아서 각 노드 별로 하나의 cloud-init 파일을 만들어줍니다.

### kraken.provider.aws
AWS에 배포할 Terraform 모델을 생성하고 입력받은 AWS 인증정보를 통해 ELB, Route53 설정을 합니다. Terraform 모델을 통해 AWS에 자원을 배포합니다. 배포된 VM은 cloud-init 스크립트를 실행시켜서 개별 노드 단위의 설치를 수행합니다.

### kraken.ssh.aws
전체 클러스터 노드의 정보를 수집해서 ssh 인벤토리를 만듭니다.

### kraken.readiness
end-user admin 인증 정보를 만들어서 사용자를 등록해주고 api server 에 인증 설정을 합니다. RBAC 정책도 적용합니다.
   
### kraken.fabric.flannel
flannel 네트워크 플러그인을 설치합니다.

### kraken.services
클러스터 서비스, repo, namespace 를 설정합니다. dex 서비스를 생성합니다. helm 서비스를 생성합니다. 차트를 설치합니다.

## 쿠버네티스 클러스터 생성 워크플로우 상세

### kraken.config
1. Check if configuration file exists
1. Include configuration variables from defaults file
1. Include configuration variables
1. expand default configuration and register the config fact
1. Non-recursively combine defaults and user config expand configuration and register the config fact
1. Trigger a fatal error
1. Set the kubernetes cloud provider to {{ kraken_config.provider }}
1. Set the kubernetes cloud provider to none
1. Set default kubernetes basic user if not defined
1. Set empty kubernetes authz dic if not defined
1. Generate default kubernetes basic auth if not defined
1. Retrive kube_basic_auths which have no password from kraken_config
1. Remove auths which have no password from kube_basic_auths
1. Generate password for the auths
1. Merge the kube basic auths to kraken_config
1. Set the provider type
1. Generate random prefix if required
1. Get oidc provider values from cluster services
1. Retrieve issuer URL
1. Retrieve domain value from
1. Set oidc values to kraken_config.kubeAuth.authn

### kraken.cluster_common
1. Make sure generated folder for cloud init snippets is there
1. Generate etcd.units.setup-network-environment.part files
1. Generate node.units.setup-network-environment.part files
1. Generate master.units.setup-network-environment.part files
1. Make sure generated folder for certs is there
1. Generate self-signed CA key
1. Generate self-signed CA
1. Generate etcd .write_files.cert-authority.part files
1. Generate node .write_files.cert-authority.part files
1. Generate master .write_files.cert-authority.part files
1. Generate etcd .coreos.update.part files
1. Generate master .coreos.update.part files
1. Generate node .coreos.update.part files
1. Generate etcd .units.format-storage.part files
1. Generate etcd .units.mount.part files
1. Generate master .units.format-storage.part files
1. Generate master .units.mount.part files
1. Generate node .units.format-storage.part files
1. Generate node .units.mount.part files
1. Generate etcd .locksmith.part files
1. Generate master .locksmith.part files
1. Generate node .locksmith.part files
1. Generate etcd .units.docker-wait-for-mounts.part files
1. Generate master .units.docker-wait-for-mounts.part files
1. Generate node .units.docker-wait-for-mounts.part files

### kraken.etcd.docker
1. Generate etcd .units.etcd.part files	    
1. Generate kraken-ssl .units.etcd.part files	

### kraken.master.docker
1. Make sure generated folder for generated key is there	
1. Generate self-signed service account key	
1. Extract service account public key	
1. Generate master api-server.yaml	
1. Generate master controller-manager.yaml	
1. Generate master kube-proxy.yaml	
1. Generate master scheduler.yaml	
1. Generate master kubelet kubeconfig	
1. Generate master writefiles kubeconfig	
1. Generate master basc auth csv	
1. Generate master writefiles basicauth	
1. Generate master writefiles service account pem	
1. Generate master writefiles manifests	
1. Generate master.units.kraken-apiserver-ssl.part	
1. Generate master.units.kubelet.part	

### kraken.node.docker
1. Generate node kube proxy.yaml	
1. Generate kubelet kubeconfig	
1. Generate writefiles kubeconfig	
1. Generate writefiles manifests	
1. Generate node units.kraken-worker-ssl.part	
1. Generate node units.kubelet.part

### kraken.assembler
1. Create a list of file for master
1. Set kraken_master_parts
1. Generate node master cloud init
1. Create a list of file for nodes
1. Generate node cloud init
1. Create a list of file for nodes
1. Generate etcd cloud init

### kraken.provider.aws
1. Set cert variable if required	
1. Set cert variable if required	
1. Make sure generated folder for certs is there	
1. Generate api server SSL options	
1. Generate APIServer Loadbalancer key	
1. Generate APIServer Loadbalancer CSR	
1. Sign APIServer Loadbalancer CSR	
1. Generate Generic Cluster key	
1. Create terraform folder	
1. Create module folders	
1. Generate kraken.provider.aws.tf file	
1. Generate module files	
1. Get modules	
1. Run cluster {{kraken_action}}	
1. Get kraken endpoint	
1. Set the kraken end point fact	
1. Get kraken aws_route53_zone.private_zone.zone_id	
1. Write zone id to file (THANKS, TERRAFORM)	
1. Kill off the hosted zone using cli53 (THANKS, TERRAFORM)	
1. Remove the route 53 zone from state (THANKS, TERRAFORM)	
1. Check for terraform state file	
1. Run terraform destroy	
1. clean the terraform state generated prefix and other misc files.	

### kraken.ssh.aws
1. Gather inventory of all cluster nodes	
1. Generate ssh inventory	

### kraken.readiness
1. Setup readiness type	
1. Setup readiness value	
1. Setup readiness value	
1. Setup readiness value	
1. Setup readiness wait	
1. Generate end-user admin key	
1. Generate end-user admin csr	
1. Generate end-user admin crt	
1. create kubeconfig entry	
1. Retrive default user from authn list	
1. create user entry	
1. create context entry	
1. set current context	
1. Get needed number of nodes	
1. Get timestamp before api server wait	
1. Fetch k8s api server address	
1. Wait for api server to become available in case it's not	
1. Get timestamp after api server wait	
1. Set remaining time fact	
1. Make sure generated folder for RBAC policy is there	
1. Generate RBAC policy file	
1. Get needed number of masters	
1. Wait until API server up	
1. Remove existing RBAC policy	
1. Bootstrap RBAC policy	
1. Get all nodes	

### kraken.fabric.flannel
1. Ensuring fabric directory exists	
1. Generate canal deployment file	
1. Generate canal configuration file	
1. Wait for api server to become available in case it's not	
1. check kube-networking namespace state	
1. Ensure the kube-networking namespace exists	
1. check kube-networking namespace state	
1. Confirm kube-networking namespace created	
1. Deploy canal configuration	
1. Deploy canal daemonset	
      
### kraken.fabric.calico
1. Display calico config	

### kraken.services
1. Create Helm home	
1. Set cluster services fact	
1. Set cluster repos fact	
1. Set cluster namespaces fact	
1. Generate dex key	
1. Generate dex csr	
1. Generate dex pem	
1. Generate dex service Tls.Ca	
1. Generate dex service Tls.Cert	
1. Generate dex service Tls.Key	
1. Retrive dex service from cluster services	
1. Remove the dex service from cluster services	
1. Create default TLS values to dex service	
1. Merge dex modified dex service to cluster services	
1. Display Service Configuration	
1. See if tiller rc if present	
1. Collect all services	
1. Register services fact	
1. Set services info	
1. Clean up releases	
1. Clean up tiller if present	
1. Clean up services	
1. Delete all service namespaces	
1. Get vpc id	
1. Set vpc_id fact	
1. Wait for ELBs to be deleted	
1. Create all service namespaces	
1. create helm command string	
1. create helm command string	
1. create helm init command string	
1. create helm init command string	
1. Wait for api server to become available in case it's not	
1. Init helm dry-run	
1. Init helm	
1. Wait for tiller to be ready	
1. Remove helm repositories	
1. Add helm repositories	
1. Save all config values to files	
1. Install charts dry-run	
1. Install charts	
