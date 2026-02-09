docker rm -fv isvaop
docker rm -fv iviawrprp1
docker rm -fv iviadsc
docker rm -fv iviaruntime
docker rm -fv iviaconfig
docker rm -fv openldap
docker rm -fv postgresql
docker volume rm iviaconfig
docker rm -fv iviaop
docker volume rm libldap
docker volume rm libsecauthority
docker volume rm ldapslapd
docker volume rm pgdata
docker network rm ivia
echo "Done."
