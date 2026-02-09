echo -n "Docker Username: "
read dusername
echo -n "Docker Password: "
read -s dpassword
echo
echo -n "Docker E-mail: "
read demail
kubectl delete secret dockerlogin &> /dev/null
kubectl create secret docker-registry dockerlogin \
  --docker-username=$dusername \
  --docker-password=$dpassword \
  --docker-email=$demail
