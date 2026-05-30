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




<Strong>
  You don't need the multi-agent Workflow tool here — you need a clear runbook. Here's the full flow for tomorrow, in execution order, starting from AWS login. Everything below assumes the deployment assets we built today are already in the repo.

🌅 Step 0 — Morning prep (local machine, ~15 min)
0.1 Install the tools (once, if not already):

AWS CLI v2, eksctl, kubectl, helm, Docker Desktop, Git.
Verify:

aws --version; eksctl version; kubectl version --client; helm version; docker --version
0.2 Log into AWS Console → create an IAM user for yourself (don't use root):

AWS Console → IAM → Users → Create user (e.g. fitness-devops)
Attach policy AdministratorAccess (fine for a capstone; production would scope it down — note that as an assumption in your docs)
Go to the user → Security credentials → Create access key → "CLI" → copy the Access key ID + Secret
0.3 Configure the CLI (this is your "AWS login" for the terminal):


aws configure
# AWS Access Key ID:     <paste>
# AWS Secret Access Key: <paste>
# Default region name:   us-east-1
# Default output format: json
aws sts get-caller-identity   # confirms you're logged in
📋 Phase 1 — Jira planning (do this first, ~20 min)
Create a project (Scrum/Kanban).
Epic: Fitness Tracker – Cloud-Native Deployment on AWS EKS
User Stories under it (one per phase area):
Source control & PR workflow
Containerization & Docker Hub
EKS cluster setup
Bastion host access
Kubernetes deployment (Deploy/Svc/CM/Secret/LB)
Persistent storage
Helm packaging
Documentation
Add Subtasks to each story (e.g. under EKS: "create cluster.yaml", "run eksctl", "verify nodes").
Assign all to yourself, move to In Progress as you go. Screenshot the board — it's a deliverable.
🗂️ Phase 2 — GitHub repo + PR workflow (~20 min)
Direct commits to main are not allowed — this is graded.


cd "e:\FITNESS APP MILESTONE\Fitness_Tracker"
git init
git add .
git commit -m "Initial deployment assets: Dockerfile, k8s manifests, Helm chart"
git branch -M main
git remote add origin https://github.com/<you>/Fitness_Tracker.git
git push -u origin main
Then on GitHub:

Settings → Branches → Add branch protection rule for main:
✅ Require a pull request before merging
✅ Require approvals (1)
From now on, all changes go: feature branch → push → Pull Request → review → approve → merge (that's Phase 10, demonstrated live at the end).
🐳 Phase 3 & 4 — Build & push your image to Docker Hub (~15 min)

docker login                                   # your Docker Hub creds
docker build -t nanineelapu/fitness-tracker:1.0.0 -t nanineelapu/fitness-tracker:latest .
docker push nanineelapu/fitness-tracker:1.0.0
docker push nanineelapu/fitness-tracker:latest
Note the tagging strategy (1.0.0 semantic version + latest) in your docs — that satisfies "versioning conventions."

☁️ Phase 5 — Create the EKS cluster (~20–25 min, mostly waiting)

eksctl create cluster -f eks/cluster.yaml      # creates VPC, subnets, nodes, EBS CSI addon
aws eks update-kubeconfig --name fitness-tracker-cluster --region us-east-1
kubectl get nodes                               # should show 2 Ready nodes
This is the longest step (~20 min). The cluster.yaml we built already includes OIDC + the EBS CSI driver, which Phase 8 needs.

🔐 Phase 6 — Bastion host (decision needed — see below)
The case study wants admin to go through a bastion, not directly. Two ways:

Option A (simple): Launch a small EC2 (t3.micro, Amazon Linux) in the cluster's public subnet, SSH in, install kubectl/aws-cli/helm, and run all the kubectl/helm commands from there. Cluster API stays public, but you administer via the bastion.
Option B (true production): Make the cluster API endpoint private, put the bastion in the public subnet as the only way to reach it. More correct, more setup.
I'd recommend Option B for a capstone (it's the "production" answer), but it requires a small edit to eks/cluster.yaml before Phase 5. Tell me which you want and I'll wire up the exact config + bastion launch commands — I'll ask you below.

On the bastion, the flow is:


aws configure                                  # bastion's IAM creds
aws eks update-kubeconfig --name fitness-tracker-cluster --region us-east-1
kubectl get nodes
🚀 Phase 7, 8, 9 — Deploy (from the bastion) (~10 min)
Easiest path — Helm (covers Phase 7 + 9 at once):


git clone https://github.com/<you>/Fitness_Tracker.git
cd Fitness_Tracker
helm install fitness ./Fitness_Chart
kubectl get pods,svc,pvc,statefulset
Get the external URL (Phase 7 = externally accessible):


kubectl get svc fitness-tracker-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# open http://<that-hostname> in a browser
Verify persistent storage (Phase 8) — this is graded, so demo it:


kubectl get pvc                                # mongodb-storage-mongodb-0 = Bound
# add some data via the app, then:
kubectl delete pod mongodb-0                   # pod dies...
kubectl get pod -w                             # ...reschedules, re-mounts same EBS volume
# refresh the app → data is still there ✅  (screenshot this)
🔄 Phase 10 — Release workflow (demo it live, ~10 min)
Make a real change to prove the workflow:


git checkout -b feature/update-replicas
# edit Fitness_Chart/values.yaml: app.replicas 2 -> 3
git commit -am "Scale app to 3 replicas"
git push origin feature/update-replicas
Open a PR → approve → merge on GitHub, then on the bastion:


git pull
helm upgrade fitness ./Fitness_Chart
kubectl get pods                               # now 3 app pods
Screenshot the PR + the rolling update.

📄 Documentation (deliverable)
Write a README.md / DEPLOYMENT.md covering: architecture diagram, design decisions (StatefulSet+EBS for persistence, gp3 Retain, ConfigMap vs Secret split, bastion choice), and the commands above. I can generate this for you.

🌙 End of day — teardown (so it doesn't bill overnight)
Same as tonight: helm uninstall fitness → eksctl delete cluster -f eks/cluster.yaml --wait.

Two quick decisions so tomorrow is smooth:

FINAL DEPLOY

<Strong>
  ✅ DONE SO FAR
Hospital App (Milestone 1 app) — COMPLETE
Phase	Done
Docker build + push	nanineelapu/hospital-app:1.0.0 on Docker Hub ✅
EKS cluster + bastion	Created, connected ✅
K8s deploy (kubectl)	Pods Running ✅
Exposed via LoadBalancer	App opened in browser ✅
Helm packaging	helm install hospital ✅
Fixes learned	placeholder→username, 1 replica for 1 node
Fitness App — SETUP started
✅ Forked + cloned Fitness_Tracker
✅ On branch feature/deployment-assets (correct PR workflow!)
✅ Branch protection rule added on GitHub
✅ Analyzed code: Node18 + Express, port 5000, MongoDB (MONGODB_URI)
📅 TOMORROW — Fitness App (the flow)
⚠️ STEP 0 — Fix the broken files FIRST (I'll generate these for you)
Three things in the repo are wrong and will fail grading:

Image is someone else's (pulkit197/...) → use your image
MongoDB uses emptyDir → not persistent (fails Phase 8) → switch to EBS storage
Helm chart isn't templated, no values.yaml (fails Phase 9)
👉 First thing tomorrow: ask me to generate the corrected files. I'll give you: storageclass.yaml, persistent MongoDB (StatefulSet + PVC), a Secret, your-image deployment, cluster.yaml, and a proper Helm chart with values.yaml.

STEP 1 — Commit on your branch & open PR (Phase 2 + 10)

git add .
git commit -m "Add production deployment assets: Docker, K8s, Helm, persistent storage"
git push origin feature/deployment-assets
Then on GitHub: Compare & pull request → base master ← feature/deployment-assets → create PR → merge. 📸 screenshot PR.

STEP 2 — Build & push YOUR image (Phase 3 + 4)

docker login
docker build -t nanineelapu/fitness-tracker:1.0.0 .
docker push nanineelapu/fitness-tracker:1.0.0
STEP 3 — Create the EKS cluster (Phase 5) — Seoul region

eksctl create cluster -f eks/cluster.yaml   # region: ap-northeast-2
(~15–20 min)

STEP 4 — Bastion host (Phase 6)
Launch a t3.micro EC2 in the cluster's VPC, connect via PuTTY, install aws/kubectl/helm, aws configure with same keys.

STEP 5 — Deploy + persistent storage (Phase 7 + 8)

kubectl apply -f eks/storageclass.yaml
kubectl apply -f k8s/    # secret, configmap, mongodb (persistent), app
kubectl get pods -w
STEP 6 — Expose & open (Phase 7)

kubectl get svc fitness-tracker-service   # copy EXTERNAL-IP → open http://that
STEP 7 — Helm version (Phase 9)

kubectl delete -f k8s/
helm lint Fitness_Chart
helm install fitness ./Fitness_Chart
kubectl get pods
STEP 8 — Prove storage (Phase 8 deliverable)

kubectl delete pod mongodb-0   # add data first, then delete
kubectl get pods -w            # comes back, data survives
STEP 9 — Documentation + Jira (Phase 1 + final)
Update Jira board to Done, write README with screenshots.

🎯 First action tomorrow
Just say: "generate the corrected Fitness files" — and I'll write all of them into your feature/deployment-assets branch. Everything else above flows from there.

💡 You deleted the Hospital cluster — good, that stops the AWS bill overnight. 👍

Sleep well — you're in great shape. 🚀
</Strong>
eksctl create cluster --name hospital-eks --region ap-northeast-2 --without-nodegroup

eksctl create nodegroup --cluster hospital-eks --region ap-northeast-2 --name ng-workers --node-type t3.medium --nodes 2 --nodes-min 2 --nodes-max 3


eksctl create cluster --name fitness-tracker-cluster --region ap-southeast-2 --version 1.30 --without-nodegroup --with-oidc
eksctl create nodegroup --cluster fitness-tracker-cluster --region ap-southeast-2 --name ng-1 --node-type t3.medium --nodes 2 --nodes-min 2 --nodes-max 3 --node-volume-size 20 --managed
eksctl create cluster --name hospital-eks --region ap-southeast-2 --without-nodegroup
eksctl create nodegroup --cluster hospital-eks --region ap-southeast-2 --name ng-workers --node-type t3.medium --nodes 2 --nodes-min 2 --nodes-max 3
