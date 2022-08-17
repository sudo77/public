
#per cluster... select context first

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard   

kubectl expose deployment -n kubernetes-dashboard kubernetes-dashboard --type=LoadBalancer --name=kubernetes-dashboard-public

kubectl get -n kubernetes-dashboard svc kubernetes-dashboard-public

kubectl describe -n kubernetes-dashboard secret kubernetes-dashboard-token