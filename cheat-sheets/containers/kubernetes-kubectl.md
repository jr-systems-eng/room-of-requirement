# Kubernetes / kubectl

Quick-reference for a small cluster or lab: inspect resources, deploy workloads, expose services, troubleshoot pods, and understand what Kubernetes is doing.

## Cluster context

```bash
kubectl version
kubectl cluster-info
kubectl config get-contexts
kubectl config current-context
kubectl config use-context CONTEXT
kubectl get nodes -o wide
```

## Namespaces

```bash
kubectl get namespaces
kubectl get all -n NAMESPACE
kubectl config set-context --current --namespace=NAMESPACE
```

## Common resource inspection

```bash
kubectl get pods -o wide
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl get configmaps
kubectl get secrets
kubectl get events --sort-by=.lastTimestamp
```

Describe when something looks wrong:

```bash
kubectl describe pod POD
kubectl describe deployment DEPLOYMENT
kubectl describe service SERVICE
kubectl describe node NODE
```

## Apply and delete manifests

```bash
kubectl apply -f app.yaml
kubectl diff -f app.yaml
kubectl delete -f app.yaml
```

## Deployment basics

```bash
kubectl create deployment web --image=nginx
kubectl get deployment web
kubectl get pods -l app=web
kubectl scale deployment web --replicas=3
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
```

## Expose an application

```bash
kubectl expose deployment web --type=NodePort --port=80
kubectl get svc web
```

Temporary local access:

```bash
kubectl port-forward deployment/web 8080:80
```

Then browse/curl `http://localhost:8080`.

## Logs

```bash
kubectl logs POD
kubectl logs -f POD
kubectl logs --tail=100 POD
kubectl logs POD -c CONTAINER
kubectl logs POD --previous
```

`--previous` is extremely useful for a container that crashed and restarted.

## Shell / execute

```bash
kubectl exec -it POD -- /bin/bash
kubectl exec -it POD -- /bin/sh
kubectl exec POD -- COMMAND
```

## Pod details / YAML

```bash
kubectl get pod POD -o yaml
kubectl get deployment DEPLOYMENT -o yaml
kubectl get service SERVICE -o yaml
```

## Resource usage

Requires metrics-server:

```bash
kubectl top nodes
kubectl top pods
```

## ConfigMap / Secret basics

```bash
kubectl create configmap app-config --from-literal=key=value
kubectl create secret generic app-secret --from-literal=password='VALUE'
kubectl get configmap app-config -o yaml
kubectl get secret app-secret -o yaml
```

Remember: Kubernetes Secrets are base64-encoded by default, not inherently encrypted at rest unless the cluster is configured for it.

Decode a value:

```bash
kubectl get secret app-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## Fast troubleshooting flow

```text
1. kubectl get pods -o wide
2. kubectl describe pod POD
3. kubectl logs POD
4. kubectl logs POD --previous
5. kubectl get events --sort-by=.lastTimestamp
6. kubectl get svc / endpoints
7. kubectl exec into pod if it stays running
8. kubectl describe node NODE if scheduling/resource issue
```

## Common pod states

```text
Pending             cannot schedule / waiting for resource
ContainerCreating   image, volume, or runtime setup in progress
CrashLoopBackOff    process repeatedly exits
ImagePullBackOff    image pull/auth/name problem
Running             pod scheduled; does not guarantee app health
Completed           expected for finished Jobs
```

## Mental model

```text
Deployment
  manages desired replicas / rollout
     |
ReplicaSet
  maintains pod count
     |
Pod
  one or more containers sharing networking/storage context

Service
  stable virtual address/DNS for a changing set of Pods
```
