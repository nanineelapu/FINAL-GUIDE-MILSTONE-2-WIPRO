# FINAL-GUIDE-MILSTONE-2-WIPRO

<Strong>
  🏥 HOSPITAL APP — FULL REVISION
App: HealthCare Plus — Node.js + Express, port 5000, MongoDB database
Image: nanineelapu/hospital-app:1.0.0

Phase 1 — Jira Planning
Created Epic → User Stories → Subtasks, assigned to yourself, tracked To Do → In Progress → Done.

Phase 2 — Accounts & AWS Keys (Steps 1–2)
Created AWS, Docker Hub, GitHub accounts. Generated AWS Access Key + Secret Key (IAM) to log in from the VM.

Phase 3 — VM + Tools (Steps 3–5)
Opened the VM with PuTTY.
Installed tools: aws cli, kubectl, eksctl, helm, docker.
aws configure → entered your keys (region, output).

aws configure        # keys + region
aws sts get-caller-identity   # verify login
Phase 4 — Start EKS Cluster (Step 6)
Created the Kubernetes cluster with eksctl from cluster.yaml:


eksctl create cluster -f eks/cluster.yaml
cluster.yaml defined: cluster name hospital-eks, node group ng-workers, t3.medium nodes, EBS CSI driver addon (for storage).

Phase 5 — GitHub Fork & Files (Step 8)
Forked the app repo, cloned it to the VM, and brought in the deploy files (Dockerfile, k8s manifests, helm chart).

Phase 6 — 🐳 Docker Build & Push (Step 9)
Packaged the app into an image and uploaded to Docker Hub:


docker login
docker build -t nanineelapu/hospital-app:1.0.0 .
docker push nanineelapu/hospital-app:1.0.0
⚠️ The fix you hit: the deployment file still had the placeholder YOUR_DOCKERHUB_USERNAME (uppercase = invalid → InvalidImageName). Fixed with:


sed -i "s#YOUR_DOCKERHUB_USERNAME#nanineelapu#g" k8s/app-deployment.yaml
Phase 7 — 🛡️ Bastion Host (Step 10)
Launched a small EC2 (bastion-host) in the same VPC as the cluster. Admin access goes through the bastion (security best practice — you don't manage the cluster directly). Installed aws/kubectl/helm on it and re-ran aws configure with the same keys.

Phase 8 — Connect & Storage (Step 11)
Applied the StorageClass (ebs-gp3) so MongoDB gets a real AWS EBS disk instead of temporary pod storage:


kubectl apply -f k8s/storageclass.yaml
Phase 9 — Deploy App (Step 12)
Applied all manifests with kubectl:


kubectl apply -f k8s/config-and-secret.yaml      # ConfigMap + Secret
kubectl apply -f k8s/mongodb-statefulset.yaml    # MongoDB + EBS volume
kubectl apply -f k8s/app-deployment.yaml         # App + LoadBalancer Service
kubectl get pods -w
⚠️ The fix you hit: only 1 node came up, so the 2nd replica was stuck Pending ("Too many pods"). Fixed with:


kubectl scale deployment hospital-app --replicas=1
Phase 10 — 🌐 Expose / Open in Browser (Step 13)
The LoadBalancer Service auto-created an AWS load balancer:


kubectl get svc hospital-service    # copy EXTERNAL-IP (...elb.amazonaws.com)
Opened http://<EXTERNAL-IP> → app live. ✅

Note: home page worked; navigation pages needed CORS fix (add LB URL to backend/app.js, rebuild, kubectl rollout restart).

Phase 11 — 💾 Prove Persistent Storage (Step 14)
Deleted the DB pod on purpose; it came back and data survived (because it's on EBS, not in the pod):


kubectl delete pod mongodb-0
kubectl get pods -w        # comes back Running, data intact
Phase 12 — 📦 Helm Packaging (Step 15)
Removed the raw manifests, then installed the same app as one configurable package:


kubectl delete -f k8s/app-deployment.yaml -f k8s/mongodb-statefulset.yaml -f k8s/config-and-secret.yaml
helm lint hospital-chart
helm install hospital ./hospital-chart
helm list
All settings live in values.yaml — no hardcoded values (Phase 9 requirement).
⚠️ You set replicas: 1 in values.yaml because of the single node.

Phase 13 — Pull Request (Step 16)
Git collaboration: branch → commit → push → PR → merge.

⚠️ Note: for Hospital you pushed directly to master (skipped PR). You're doing it properly for Fitness with feature/deployment-assets.

Phase 14 — Documentation (Step 17)
README + screenshots of each phase.

Phase 15 — 🧹 Cleanup (Step 18)
Deleted the cluster to stop AWS charges:


eksctl delete cluster --name hospital-eks --region <your-region>
🔑 Key concepts to remember (for viva)
Concept	One-liner
Docker image	A packaged box of your app, stored on Docker Hub
EKS	AWS-managed Kubernetes cluster
Pod	Smallest unit — runs your container
Deployment	Keeps N replicas of a pod running
Service (LoadBalancer)	Exposes the app to the internet via AWS ELB
ConfigMap / Secret	Non-secret / secret config injected as env vars
PVC + EBS / StorageClass	Real persistent disk so data survives pod death
StatefulSet	For databases — stable identity + storage
Bastion host	Secure jump-box; no direct cluster admin
Helm	Package manager — one chart, all values in values.yaml
kubectl apply vs helm	Manual loose files vs versioned reusable package
🐞 The 3 problems you solved (great for the report)
InvalidImageName → placeholder YOUR_DOCKERHUB_USERNAME (uppercase, invalid) → fixed with sed.
Pending / "Too many pods" → only 1 node → scaled app to 1 replica.
Stale NXDOMAIN URL → Helm recreated the LoadBalancer with a new address → got fresh URL via kubectl get svc.
</Strong>
